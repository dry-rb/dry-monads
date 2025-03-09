# frozen_string_literal: true

require "super_diff"
require "super_diff/rspec"

if Gem::Version.new("0.15.0") > SuperDiff::VERSION
  raise "SuperDiff version must be >= 0.15.0"
end

module Dry
  module Monads
    module SuperDiff
      VALUES = [
        Result::Success,
        Result::Failure,
        Maybe::Some,
        Maybe::None,
        Try::Value
      ].freeze

      EXTRACT_VALUE = {
        Result::Success => lambda(&:value!),
        Result::Failure => lambda(&:failure),
        Maybe::Some => lambda(&:value!),
        Maybe::None => lambda { |_| Unit },
        Try::Value => lambda(&:value!)
      }.freeze

      TOKEN_MAP = {
        Result::Success => "Success(",
        Result::Failure => "Failure(",
        Maybe::Some => "Some(",
        Maybe::None => "None(",
        Try::Value => "Value("
      }.freeze

      module OperationTreeFlatteners
        class MonadicValues < ::SuperDiff::Basic::OperationTreeFlatteners::CustomObject
          def open_token
            TOKEN_MAP[operation_tree.underlying_object.class]
          end

          def close_token = ")"

          def item_prefix_for(_) = ""
        end
      end

      module OperationTrees
        class MonadicValues < ::SuperDiff::Basic::OperationTrees::CustomObject
          def operation_tree_flattener_class
            OperationTreeFlatteners::MonadicValues
          end
        end
      end

      module OperationTreeBuilders
        class MonadicValues < ::SuperDiff::Basic::OperationTreeBuilders::CustomObject
          def self.applies_to?(expected, actual)
            VALUES.include?(expected.class) &&
              actual.instance_of?(expected.class)
          end

          protected

          def build_operation_tree
            OperationTrees::MonadicValues.new([], underlying_object: actual)
          end

          def attribute_names
            [:value]
          end

          private

          def establish_expected_and_actual_attributes
            @expected_attributes = get_value(expected)
            @actual_attributes = get_value(actual)
          end

          def get_value(object)
            v = EXTRACT_VALUE[object.class].(object)

            if Unit.equal?(v)
              EMPTY_HASH
            else
              {value: v}
            end
          end
        end
      end

      module Differs
        class MonadicValues < ::SuperDiff::Basic::Differs::CustomObject
          def self.applies_to?(expected, actual)
            VALUES.include?(expected.class) &&
              expected.instance_of?(actual.class)
          end

          def operation_tree_builder_class
            OperationTreeBuilders::MonadicValues
          end
        end
      end

      module InspectionTreeBuilders
        class MonadicValues < ::SuperDiff::Basic::InspectionTreeBuilders::CustomObject
          def self.applies_to?(object)
            VALUES.include?(object.class)
          end

          def call
            ::SuperDiff::Core::InspectionTree.new do |t1|
              t1.as_lines_when_rendering_to_lines(
                collection_bookend: :open
              ) do |t2|
                t2.add_text(TOKEN_MAP[object.class])

                v = EXTRACT_VALUE[object.class].(object)

                unless Unit.equal?(v)
                  t2.nested do |t3|
                    t3.add_inspection_of v
                  end
                end
                t2.add_text(")")
              end
            end
          end
        end
      end
    end
  end
end

SuperDiff.configuration.tap do |config|
  config.prepend_extra_differ_classes(Dry::Monads::SuperDiff::Differs::MonadicValues)
  config.prepend_extra_inspection_tree_builder_classes(
    Dry::Monads::SuperDiff::InspectionTreeBuilders::MonadicValues
  )
end
