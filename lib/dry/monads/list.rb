require 'dry/equalizer'

module Dry
  module Monads
    class List
      def self.[](*values)
        new(values)
      end

      def self.coerce(value)
        if value.nil?
          List.new([])
        elsif value.respond_to?(:to_ary)
          List.new(value.to_ary)
        else
          raise ArgumentError, "Can't coerce #{value.inspect} to List"
        end
      end

      include Dry::Equalizer(:value)

      attr_reader :value

      def initialize(value)
        @value = value
      end

      def bind(*args)
        if block_given?
          List.coerce(value.map { |v| yield(v, *args) }.reduce(:+))
        else
          obj, *rest = args
          List.coerce(value.map { |v| obj.call(v, *rest) }.reduce(:+))
        end
      end

      def fmap(*args)
        if block_given?
          List.new(value.map { |v| yield(v, *args) })
        else
          obj, *rest = args
          List.new(value.map { |v| obj.call(v, *rest) })
        end
      end

      def +(other)
        List.new(value + other.value)
      end

      def inspect
        "List#{ value.inspect }"
      end
      alias_method :to_s, :inspect

      alias_method :to_ary, :value
      alias_method :to_a, :to_ary

      module Mixin
        List = List
        L = List

        def List(value)
          List.coerce(value)
        end
      end
    end
  end
end
