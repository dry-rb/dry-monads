# frozen_string_literal: true

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

          matcher :"be_#{name}" do |expected = Undefined|
            predicate = "#{name}?"

            match do |actual|
              if expected_classes.any? { |klass| actual.is_a?(klass) }
                exact_match = actual.is_a?(expected_classes[0])

                if exact_match && block_arg
                  block_arg.call(extract_value.call(actual))
                elsif Undefined.equal?(expected)
                  true
                elsif exact_match
                  values_match? expected, extract_value.call(actual)
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
      end
    end
  end
end

catch_missing_const = Module.new do
  if debug_inspector_available
    def const_missing(name)
      const_name = Dry::Monads::RSpec.resolve_constant_name(name)

      if const_name
        DebugInspector.open do |dc|
          if dc.frame_binding(2).receiver.is_a?(RSpec::Core::ExampleGroup)
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

      if const_name && caller_locations(1, 1).first.path.end_with?("_spec.rb")
        Dry::Monads::RSpec.name_to_const(const_name)
      else
        super
      end
    end
  end

  define_method(:include) do |*modules|
    super(*modules).tap do
      modules.flat_map(&:ancestors).uniq.each do |c|
        c.extend(catch_missing_const) unless c.frozen?
      end
    end
  end
end

Object.extend(catch_missing_const)

RSpec.configure do |config|
  config.include Dry::Monads::RSpec::Matchers
  config.include Dry::Monads::RSpec::Constructors
  config.extend(catch_missing_const)
end
