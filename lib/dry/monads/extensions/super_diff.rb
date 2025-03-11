# frozen_string_literal: true

require "delegate"
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
        Result::Success => "Success",
        Result::Failure => "Failure",
        Maybe::Some => "Some",
        Maybe::None => "None",
        Try::Value => "Value"
      }.freeze

      class WrappedArray < ::SimpleDelegator
        def is_a?(klass) = klass <= WrappedArray
      end

      module OperationTreeFlatteners
        class MonadicValues < ::SuperDiff::Basic::OperationTreeFlatteners::CustomObject
          private

          def initialize(...)
            super

            obj = operation_tree.underlying_object
            @klass = obj.class
            @array = EXTRACT_VALUE[@klass].(obj).is_a?(::Array)
          end

          protected

          def array? = @array

          def open_token = "#{TOKEN_MAP[@klass]}#{array? ? "[" : "("}"

          def close_token = array? ? "]" : ")"

          def item_prefix_for(_) = ""
        end

        class WrappedArray < ::SuperDiff::Basic::OperationTreeFlatteners::Array
          protected

          def build_tiered_lines = inner_lines

          # prevent super_diff from adding a newline after the open token
          # for arrays
          def build_lines_for_non_change_operation(*)
            @indentation_level -= 1
            super
          ensure
            @indentation_level += 1
          end

          def open_token = ""

          def close_token = ""
        end
      end

      module OperationTrees
        class MonadicValues < ::SuperDiff::Basic::OperationTrees::CustomObject
          def operation_tree_flattener_class
            OperationTreeFlatteners::MonadicValues
          end
        end

        class WrappedArray < ::SuperDiff::Basic::OperationTrees::Array
          def self.applies_to?(value)
            value.is_a?(::Dry::Monads::SuperDiff::WrappedArray)
          end

          def operation_tree_flattener_class
            OperationTreeFlatteners::WrappedArray
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

          def attribute_names = [:value]

          private

          def establish_expected_and_actual_attributes
            @expected_attributes = get_value(expected)
            @actual_attributes = get_value(actual)
          end

          def get_value(object)
            v = EXTRACT_VALUE[object.class].(object)

            if Unit.equal?(v)
              EMPTY_HASH
            elsif v.is_a?(::Array)
              {value: ::Dry::Monads::SuperDiff::WrappedArray.new(v)}
            else
              {value: v}
            end
          end
        end

        class WrappedArray < ::SuperDiff::Basic::OperationTreeBuilders::Array
          def self.applies_to?(expected, actual)
            expected.is_a?(::Dry::Monads::SuperDiff::WrappedArray) &&
              actual.is_a?(::Dry::Monads::SuperDiff::WrappedArray)
          end

          private

          def operation_tree
            @operation_tree ||= OperationTrees::WrappedArray.new([])
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
                v = EXTRACT_VALUE[object.class].(object)

                t2.add_text(TOKEN_MAP[object.class])

                unless v.is_a?(::Array)
                  t2.add_text("(")
                end

                unless Unit.equal?(v)
                  t2.nested do |t3|
                    t3.add_inspection_of v
                  end
                end

                unless v.is_a?(::Array)
                  t2.add_text(")")
                end
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
  config.prepend_extra_operation_tree_builder_classes(
    Dry::Monads::SuperDiff::OperationTreeBuilders::WrappedArray
  )
end
