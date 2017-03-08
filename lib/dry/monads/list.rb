require 'dry/equalizer'

module Dry
  module Monads
    class List
      # Builds a list.
      #
      # @param [Array<Object>] values List elements
      # @return [List]
      def self.[](*values)
        new(values)
      end

      # Coerces a value to a list. `nil` will be coerced to an empty list.
      #
      # @param [Object] value Value
      # @return [List]
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

      # Internal array value
      attr_reader :value

      # @api private
      def initialize(value)
        @value = value
      end

      # Lifts a block/proc and runs it against each member of the list.
      # The block must return a value coercible to a list.
      # As in other monads if no block given the first argument will
      # be treated as callable and used instead.
      #
      # @example
      #   Dry::Monads::List[1, 2].bind { |x| [x + 1] } # => List[2, 3]
      #   Dry::Monads::List[1, 2].bind(-> x { [x, x + 1] }) # => List[1, 2, 2, 3]
      #
      # @param [Array<Object>] args arguments will be passed to the block or proc
      # @return [List]
      def bind(*args)
        if block_given?
          List.coerce(value.map { |v| yield(v, *args) }.reduce(:+))
        else
          obj, *rest = args
          List.coerce(value.map { |v| obj.(v, *rest) }.reduce(:+))
        end
      end

      # Maps a block over the list. Acts as `Array#map`.
      # As in other monads if no block given the first argument will
      # be treated as callable and used instead.
      #
      # @example
      #   Dry::Monads::List[1, 2].fmap { |x| x + 1 } # => List[2, 3]
      #
      # @param [Array<Object>] args arguments will be passed to the block or proc
      # @return [List]
      def fmap(*args)
        if block_given?
          List.new(value.map { |v| yield(v, *args) })
        else
          obj, *rest = args
          List.new(value.map { |v| obj.(v, *rest) })
        end
      end

      # Maps a block over the list. Acts as `Array#map`.
      # Requires a block.
      #
      # @return [List]
      def map(&block)
        if block
          fmap(block)
        else
          raise ArgumentError, "Missing block"
        end
      end

      # Concatenates two lists.
      #
      # @example
      #   Dry::Monads::List[1, 2] + Dry::Monads::List[3, 4] # => List[1, 2, 3, 4]
      #
      # @param [List] other Other list
      # @return [List]
      def +(other)
        List.new(value + other.value)
      end

      # Returns a string representation of the list.
      #
      # @example
      #   Dry::Monads::List[1, 2, 3].inspect # => "List[1, 2, 3]"
      #
      # @return [String]
      def inspect
        "List#{ value.inspect }"
      end
      alias_method :to_s, :inspect

      # Coerces to an array
      alias_method :to_ary, :value
      alias_method :to_a, :to_ary

      # Empty list
      EMPTY = List.new([].freeze).freeze

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
