# frozen_string_literal: true

# The extension hooks `const_missing` globally, so make loading it again a no-op
return if defined?(::Dry::Monads::RSpec::MissingConstants)

require "rspec/matchers"

debug_inspector_available =
  begin
    require "debug_inspector"
    defined?(DebugInspector)
  rescue LoadError
    false
  end

module Dry
  module Monads
    module RSpec
      module Matchers
        extend ::RSpec::Matchers::DSL

        PREDICATES = {
          failure: {
            expected_classes: [
              ::Dry::Monads::Result::Failure,
              ::Dry::Monads::Maybe::None,
              ::Dry::Monads::Try::Error
            ],
            extract_value: :failure.to_proc
          },
          success: {
            expected_classes: [
              ::Dry::Monads::Result::Success,
              ::Dry::Monads::Maybe::Some,
              ::Dry::Monads::Try::Value
            ],
            extract_value: :value!.to_proc
          },
          some: {
            expected_classes: [::Dry::Monads::Maybe::Some],
            extract_value: :value!.to_proc
          }
        }.freeze

        CONSTRUCTOR_CLASSES = PREDICATES.values.flat_map { |definition|
          definition[:expected_classes]
        }.freeze

        PREDICATES.each do |name, args|
          args => {expected_classes:, extract_value:}
          expected_constructors = expected_classes.map(&:name).map do |c|
            c.split("::").last
          end

          matcher :"be_#{name}" do |*expected_args|
            predicate = "#{name}?"
            expected = expected_args.fetch(0, Undefined)

            match do |actual|
              if expected_classes.any? { |klass| actual.is_a?(klass) }
                exact_match = actual.is_a?(expected_classes[0])

                if exact_match && block_arg
                  block_arg.call(extract_value.call(actual))
                elsif Undefined.equal?(expected)
                  true
                elsif exact_match
                  extract_value.call(actual) == expected
                else
                  false
                end
              elsif actual.respond_to?(predicate)
                actual.__send__(predicate)
              else
                false
              end
            end

            failure_message do |actual|
              if expected_classes.none? { |klass| actual.is_a?(klass) }
                if actual.respond_to?(predicate)
                  "expected #{actual.inspect}.#{predicate} to return truthy value, " \
                    "but it returned false or nil"
                elsif expected_classes.size > 1
                  "expected #{actual.inspect} to be one of the following values: " \
                    "#{expected_constructors.join(", ")} or respond to #{predicate}, " \
                    "but it's #{actual.class}"
                else
                  "expected #{actual.inspect} to be a #{expected_constructors[0]} value " \
                    "or respond to #{predicate}, but it's #{actual.class}"
                end
              elsif actual.is_a?(expected_classes[0]) && block_arg
                "expected #{actual.inspect} to have a value satisfying the given block"
              else
                "expected #{actual.inspect} to have value #{expected.inspect}, " \
                  "but it was #{extract_value.call(actual).inspect}"
              end
            end

            failure_message_when_negated do |actual|
              if expected_classes.none? { |klass| actual.is_a?(klass) }
                if actual.respond_to?(predicate)
                  "expected #{actual.inspect}.#{predicate} to return falsey value, " \
                    "but it returned truthy value"
                else
                  "expected #{actual.inspect} to respond to #{predicate}, " \
                    "but it doesn't"
                end
              elsif expected_classes.size > 1
                "expected #{actual.inspect} to not be one of the following values: " \
                  "#{expected_constructors.join(", ")}, but it is"
              else
                "expected #{actual.inspect} to not be a #{expected_constructors[0]} value, " \
                  "but it is"
              end
            end
          end

          alias_matcher :"be_a_#{name}", :"be_#{name}"
        end

        matcher :be_none do
          match { |actual| actual.is_a?(::Dry::Monads::Maybe::None) }

          failure_message do |actual|
            "expected #{actual.inspect} to be none"
          end

          failure_message_when_negated do |actual|
            "expected #{actual.inspect} to not be none"
          end
        end
      end

      Constructors = Monads[:result, :maybe]

      CONSTANTS = %i[Success Failure Some None List].to_set

      NESTED_CONSTANTS = CONSTANTS.to_set { |c| "::#{c}" }

      class << self
        def resolve_constant_name(name)
          if CONSTANTS.include?(name)
            name
          elsif NESTED_CONSTANTS.any? { |c| name.to_s.end_with?(c) }
            name[/::(\w+)$/, 1].to_sym
          else
            nil
          end
        end

        def name_to_const(name)
          case name
          in :Success
            ::Dry::Monads::Result::Success
          in :Failure
            ::Dry::Monads::Result::Failure
          in :Some
            ::Dry::Monads::Maybe::Some
          in :None
            ::Dry::Monads::Maybe::None
          in :List
            ::Dry::Monads::List
          end
        end

        def catch_missing_constants_in_nesting(example_group)
          block = example_group.metadata[:block]
          return unless block

          block.binding.eval("Module.nesting", __FILE__, __LINE__).each do |mod|
            mod.extend(MissingConstants) unless mod.frozen?
          end
        end

        def example_group_caller?(debug_context)
          (2...debug_context.backtrace_locations.size).each do |index|
            caller_binding = debug_context.frame_binding(index)
            next unless caller_binding

            return caller_binding.receiver.is_a?(::RSpec::Core::ExampleGroup)
          end

          false
        end

        def rspec_example_context?(location)
          example_group_instance = ::RSpec.current_example&.example_group_instance
          return false unless example_group_instance

          spec_example_block?(location) || example_group_method?(example_group_instance, location)
        end

        private

        def spec_example_block?(location)
          location.path.end_with?("_spec.rb") && location.label.include?("block")
        end

        def example_group_method?(example_group_instance, location)
          method_name = caller_method_name(location)
          return false unless method_name

          owner = example_group_instance.method(method_name).owner

          ![::BasicObject, ::Kernel, ::Object].include?(owner)
        rescue NameError
          false
        end

        def caller_method_name(location)
          label = location.label.to_s
          return nil if label.include?("block")

          label.split(/[.#]/).last&.to_sym
        end
      end
    end
  end
end

Dry::Monads::RSpec::MissingConstants = Module.new do
  if debug_inspector_available
    def const_missing(name)
      const_name = Dry::Monads::RSpec.resolve_constant_name(name)

      if const_name
        DebugInspector.open do |dc|
          if Dry::Monads::RSpec.example_group_caller?(dc)
            Dry::Monads::RSpec.name_to_const(const_name)
          else
            super
          end
        end
      else
        super
      end
    end
  else
    def const_missing(name)
      const_name = Dry::Monads::RSpec.resolve_constant_name(name)

      if const_name && Dry::Monads::RSpec.rspec_example_context?(caller_locations(1, 1).first)
        Dry::Monads::RSpec.name_to_const(const_name)
      else
        super
      end
    end
  end
end

Dry::Monads::RSpec::MissingConstants.module_eval do
  define_method(:include) do |*modules|
    super(*modules).tap do
      modules.flat_map(&:ancestors).uniq.each do |c|
        c.extend(Dry::Monads::RSpec::MissingConstants) unless c.frozen?
      end
    end
  end
end

Object.extend(Dry::Monads::RSpec::MissingConstants)

RSpec.configure do |config|
  config.include Dry::Monads::RSpec::Matchers
  config.include Dry::Monads::RSpec::Constructors
  config.extend(Dry::Monads::RSpec::MissingConstants)
  config.on_example_group_definition do |example_group|
    Dry::Monads::RSpec.catch_missing_constants_in_nesting(example_group)
  end
end
