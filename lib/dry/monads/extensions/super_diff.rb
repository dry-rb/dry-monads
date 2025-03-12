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

      EXTRACT_VALUE_MAP = {
        Result::Success => lambda(&:value!),
        Result::Failure => lambda(&:failure),
        Maybe::Some => lambda(&:value!),
        Maybe::None => lambda { |_| Unit },
        Try::Value => lambda(&:value!)
      }.freeze

      EXTRACT_VALUE = lambda do |v|
        EXTRACT_VALUE_MAP[v.class].(v)
      end

      IS_ARRAY = lambda do |v|
        EXTRACT_VALUE.(v).is_a?(::Array)
      end

      IS_HASH = lambda do |v|
        EXTRACT_VALUE.(v).is_a?(::Hash)
      end

      TOKEN_MAP = {
        Result::Success => "Success",
        Result::Failure => "Failure",
        Maybe::Some => "Some",
        Maybe::None => "None",
        Try::Value => "Value"
      }.freeze

      class Tuple < ::SimpleDelegator
        def is_a?(klass) = klass <= Tuple
      end

      class Dict < ::SimpleDelegator
        def is_a?(klass) = klass <= Dict
      end

      module OTFlatteners
        module MonasAsCollectionConstructor
          def call = tiered_lines

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

        class RegularConstructor < ::SuperDiff::Basic::OperationTreeFlatteners::CustomObject
          private

          def initialize(...)
            super

            @klass = operation_tree.underlying_object.class
          end

          def open_token = "#{TOKEN_MAP[@klass]}("

          def close_token = ")"

          def item_prefix_for(_) = ""
        end

        class TupleConstructor < RegularConstructor
          private

          def open_token = "#{TOKEN_MAP[@klass]}["

          def close_token = "]"
        end

        class Tuple < ::SuperDiff::Basic::OperationTreeFlatteners::Array
          include MonasAsCollectionConstructor
        end

        class Dict < ::SuperDiff::Basic::OperationTreeFlatteners::Hash
          include MonasAsCollectionConstructor
        end
      end

      module OT
        class RegularConstructor < ::SuperDiff::Basic::OperationTrees::CustomObject
          def self.applies_to?(value) = VALUES.include?(value.class)

          def operation_tree_flattener_class = OTFlatteners::RegularConstructor
        end

        class TupleConstructor < RegularConstructor
          def self.applies_to?(value) = super && IS_ARRAY.call(value)

          def operation_tree_flattener_class = OTFlatteners::TupleConstructor
        end

        class Tuple < ::SuperDiff::Basic::OperationTrees::Array
          def self.applies_to?(value) = value.is_a?(::Dry::Monads::SuperDiff::Tuple)

          def operation_tree_flattener_class = OTFlatteners::Tuple
        end

        class Dict < ::SuperDiff::Basic::OperationTrees::Hash
          def self.applies_to?(value) = value.is_a?(::Dry::Monads::SuperDiff::Dict)

          def operation_tree_flattener_class = OTFlatteners::Dict
        end
      end

      module OTBuilders
        class CompareDefault < ::SuperDiff::Basic::OperationTreeBuilders::CustomObject
          def self.applies_to?(expected, actual)
            VALUES.include?(expected.class) &&
              actual.instance_of?(expected.class)
          end

          protected

          def build_operation_tree
            OT::RegularConstructor.new([], underlying_object: actual)
          end

          def attribute_names = [:value]

          private

          def establish_expected_and_actual_attributes
            @expected_attributes = get_value(expected)
            @actual_attributes = get_value(actual)
          end

          def get_value(object)
            v = EXTRACT_VALUE.(object)

            if Unit.equal?(v)
              EMPTY_HASH
            else
              {value: v}
            end
          end
        end

        class Tuple < ::SuperDiff::Basic::OperationTreeBuilders::Array
          def self.applies_to?(expected, actual)
            expected.is_a?(::Dry::Monads::SuperDiff::Tuple) &&
              actual.instance_of?(expected.class)
          end

          private

          def operation_tree
            @operation_tree ||= OT::Tuple.new([])
          end
        end

        class Dict < ::SuperDiff::Basic::OperationTreeBuilders::Hash
          def self.applies_to?(expected, actual)
            expected.is_a?(::Dry::Monads::SuperDiff::Dict) &&
              actual.instance_of?(expected.class)
          end

          private

          def build_operation_tree = OT::Dict.new([])
        end

        class CompareTuples < CompareDefault
          def self.applies_to?(expected, actual)
            super && IS_ARRAY.call(expected) && IS_ARRAY.call(actual)
          end

          private

          def get_value(object)
            v = EXTRACT_VALUE.(object)

            {value: ::Dry::Monads::SuperDiff::Tuple.new(v)}
          end

          def build_operation_tree
            OT::TupleConstructor.new([], underlying_object: actual)
          end
        end

        class CompareDicts < CompareDefault
          def self.applies_to?(expected, actual)
            super && IS_HASH.call(expected) && IS_HASH.call(actual)
          end

          private

          def get_value(object)
            v = EXTRACT_VALUE.(object)

            {value: ::Dry::Monads::SuperDiff::Dict.new(v)}
          end
        end
      end

      module Differs
        class CompareDefault < ::SuperDiff::Basic::Differs::CustomObject
          def self.applies_to?(expected, actual)
            VALUES.include?(expected.class) &&
              expected.instance_of?(actual.class)
          end

          def operation_tree_builder_class = OTBuilders::CompareDefault
        end

        class CompareTuples < CompareDefault
          def self.applies_to?(expected, actual)
            super && IS_ARRAY.call(expected) && IS_ARRAY.call(actual)
          end

          def operation_tree_builder_class = OTBuilders::CompareTuples
        end

        class CompareDicts < CompareDefault
          def self.applies_to?(expected, actual)
            super && IS_HASH.call(expected) && IS_HASH.call(actual)
          end

          def operation_tree_builder_class = OTBuilders::CompareDicts
        end
      end

      module ITBuilders
        class RegularConstructor < ::SuperDiff::Basic::InspectionTreeBuilders::CustomObject
          def self.applies_to?(object)
            VALUES.include?(object.class)
          end

          def call
            build_tree do |t2|
              t2.add_text("#{TOKEN_MAP[object.class]}(")

              v = EXTRACT_VALUE.(object)

              unless Unit.equal?(v)
                t2.nested do |t3|
                  t3.add_inspection_of v
                end
              end

              t2.add_text(")")
            end
          end

          private

          def build_tree(&block)
            ::SuperDiff::Core::InspectionTree.new do |t1|
              t1.as_lines_when_rendering_to_lines(
                collection_bookend: :open, &block
              )
            end
          end
        end

        class TupleConstructor < RegularConstructor
          def self.applies_to?(object) = super && IS_ARRAY.call(object)

          def call
            build_tree do |t2|
              t2.add_text(TOKEN_MAP[object.class])

              t2.nested do |t3|
                t3.add_inspection_of EXTRACT_VALUE.(object)
              end
            end
          end
        end

        class DictConstructor < RegularConstructor
          def self.applies_to?(object) = super && IS_HASH.call(object)

          def call
            build_tree do |t2|
              t2.add_text("#{TOKEN_MAP[object.class]}(")

              t2.nested do |t3|
                t3.add_inspection_of ::Dry::Monads::SuperDiff::Dict.new(
                  EXTRACT_VALUE.(object)
                )
              end

              t2.add_text(")")
            end
          end
        end

        class Dict < ::SuperDiff::Basic::InspectionTreeBuilders::Hash
          def self.applies_to?(object) = object.is_a?(::Dry::Monads::SuperDiff::Dict)

          def call
            ::SuperDiff::Core::InspectionTree.new do |t1|
              t1.only_when empty do |t2|
                t2.as_lines_when_rendering_to_lines do |t3|
                  t3.add_text "{}"
                end
              end

              t1.only_when nonempty do |t2|
                t2.nested do |t3|
                  t3.insert_hash_inspection_of(object)
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
  config.prepend_extra_differ_classes(
    Dry::Monads::SuperDiff::Differs::CompareTuples,
    Dry::Monads::SuperDiff::Differs::CompareDicts,
    Dry::Monads::SuperDiff::Differs::CompareDefault
  )
  config.prepend_extra_inspection_tree_builder_classes(
    Dry::Monads::SuperDiff::ITBuilders::TupleConstructor,
    Dry::Monads::SuperDiff::ITBuilders::DictConstructor,
    Dry::Monads::SuperDiff::ITBuilders::RegularConstructor,
    Dry::Monads::SuperDiff::ITBuilders::Dict
  )
  config.prepend_extra_operation_tree_builder_classes(
    Dry::Monads::SuperDiff::OTBuilders::Tuple,
    Dry::Monads::SuperDiff::OTBuilders::Dict
  )
end
