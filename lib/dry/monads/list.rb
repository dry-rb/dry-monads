require 'dry/equalizer'

require 'dry/monads/maybe'
require 'dry/monads/task'
require 'dry/monads/result'
require 'dry/monads/try'
require 'dry/monads/validated'
require 'dry/monads/transformer'
require 'dry/monads/curry'

module Dry
  module Monads
    # The List monad.
    class List
      class << self
        # Builds a list.
        #
        # @param values [Array<Object>] List elements
        # @return [List]
        def [](*values)
          new(values)
        end

        # Coerces a value to a list. `nil` will be coerced to an empty list.
        #
        # @param value [Object] Value
        # @param type [Monad] Embedded monad type (used in case of list of monadic values)
        # @return [List]
        def coerce(value, type = nil)
          if value.nil?
            List.new([], type)
          elsif value.respond_to?(:to_ary)
            values = value.to_ary

            if !values.empty? && type.nil? && values[0].respond_to?(:monad)
              List.new(values, values[0].monad)
            else
              List.new(values, type)
            end
          else
            raise TypeError, "Can't coerce #{value.inspect} to List"
          end
        end

        # Wraps a value with a list.
        #
        # @param value [Object] any object
        # @return [List]
        def pure(value = Undefined, type = nil, &block)
          if value.equal?(Undefined)
            new([block])
          elsif block
            new([block], value)
          else
            new([value], type)
          end
        end
      end

      extend Dry::Core::Deprecations[:'dry-monads']

      include Dry::Equalizer(:value, :type)
      include Transformer

      # Internal array value
      attr_reader :value, :type

      # @api private
      def initialize(value, type = nil)
        @value = value
        @type = type
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
      # @param args [Array<Object>] arguments will be passed to the block or proc
      # @return [List]
      def bind(*args)
        if block_given?
          List.coerce(value.map { |v| yield(v, *args) }.reduce([], &:+))
        else
          obj, *rest = args
          List.coerce(value.map { |v| obj.(v, *rest) }.reduce([], &:+))
        end
      end

      # Maps a block over the list. Acts as `Array#map`.
      # As in other monads if no block given the first argument will
      # be treated as callable and used instead.
      #
      # @example
      #   Dry::Monads::List[1, 2].fmap { |x| x + 1 } # => List[2, 3]
      #
      # @param args [Array<Object>] arguments will be passed to the block or proc
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
      # Note that this method returns an Array instance, not a List
      #
      # @return [List,Enumerator]
      def map(&block)
        if block
          fmap(block)
        else
          value.map(&block)
        end
      end

      # Concatenates two lists.
      #
      # @example
      #   Dry::Monads::List[1, 2] + Dry::Monads::List[3, 4] # => List[1, 2, 3, 4]
      #
      # @param other [List] Other list
      # @return [List]
      def +(other)
        List.new(to_ary + other.to_ary)
      end

      # Returns a string representation of the list.
      #
      # @example
      #   Dry::Monads::List[1, 2, 3].inspect # => "List[1, 2, 3]"
      #
      # @return [String]
      def inspect
        type_ann = typed? ? "<#{ type.name.split('::').last }>" : ''
        "List#{ type_ann }#{ value.inspect }"
      end
      alias_method :to_s, :inspect

      # Coerces to an array
      alias_method :to_ary, :value
      alias_method :to_a, :to_ary

      # Returns the first element.
      #
      # @return [Object]
      def first
        value.first
      end

      # Returns the last element.
      #
      # @return [Object]
      def last
        value.last
      end

      # Folds the list from the left.
      #
      # @param initial [Object] Initial value
      # @return [Object]
      def fold_left(initial)
        value.reduce(initial) { |acc, v| yield(acc, v) }
      end
      alias_method :foldl, :fold_left
      alias_method :reduce, :fold_left

      # Folds the list from the right.
      #
      # @param initial [Object] Initial value
      # @return [Object]
      def fold_right(initial)
        value.reverse.reduce(initial) { |a, b| yield(b, a) }
      end
      alias_method :foldr, :fold_right

      # Whether the list is empty.
      #
      # @return [TrueClass, FalseClass]
      def empty?
        value.empty?
      end

      # Sorts the list.
      #
      # @return [List]
      def sort
        coerce(value.sort)
      end

      # Filters elements with a block
      #
      # @return [List]
      def filter
        coerce(value.select { |e| yield(e) })
      end
      alias_method :select, :filter

      # List size.
      #
      # @return [Integer]
      def size
        value.size
      end

      # Reverses the list.
      #
      # @return [List]
      def reverse
        coerce(value.reverse)
      end

      # Returns the first element wrapped with a `Maybe`.
      #
      # @return [Maybe<Object>]
      def head
        Monads::Maybe.coerce(value.first)
      end

      # Returns list's tail.
      #
      # @return [List]
      def tail
        coerce(value.drop(1))
      end

      # Turns the list into a typed one.
      # Type is required for some operations like .traverse.
      #
      # @param type [Monad] Monad instance
      # @return [List] Typed list
      def typed(type = nil)
        if type.nil?
          if size.zero?
            raise ArgumentError, "Cannot infer a monad for an empty list"
          else
            self.class.warn(
              "Automatic monad inference is deprecated, pass a type explicitly "\
              "or use a predefined constant, e.g. List::Result\n"\
              "#{caller.find { |l| l !~ %r{(lib/dry/monads)|(gems)} }}"
            )
            self.class.new(value, value[0].monad)
          end
        else
          self.class.new(value, type)
        end
      end

      # Whether the list is types
      #
      # @return [Boolean]
      def typed?
        !type.nil?
      end

      # Traverses the list with a block (or without it).
      # This methods "flips" List structure with the given monad (obtained from the type).
      # Note that traversing requires the list to be typed.
      # Also if a block given, its returning type must be equal list's type.
      #
      # @example
      #   List<Result>[Success(1), Success(2)].traverse # => Success([1, 2])
      #   List<Maybe>[Some(1), None, Some(3)].traverse # => None
      #
      # @return [Monad] Result is a monadic value
      def traverse(proc = nil, &block)
        unless typed?
          raise StandardError, "Cannot traverse an untyped list"
        end

        cons = type.pure { |list, i| list + List.pure(i) }
        with = proc || block || Traverse[type]

        foldl(type.pure(EMPTY)) do |acc, el|
          cons.
            apply(acc).
            apply { with.(el) }
        end
      end

      # Applies the stored functions to the elements of the given list.
      #
      # @param list [List]
      # @return [List]
      def apply(list = Undefined)
        v = Undefined.default(list) { yield }
        fmap(Curry).bind { |f| v.fmap { |x| f.(x) } }
      end

      # Returns the List monad.
      #
      # @return [Monad]
      def monad
        List
      end

      # Returns self.
      #
      # @return [Result::Success, Result::Failure]
      def to_monad
        self
      end

      private

      def coerce(other)
        self.class.coerce(other)
      end

      # Empty list
      EMPTY = List.new([].freeze).freeze

      # @private
      class ListBuilder
        class << self
          alias_method :[], :new
        end

        attr_reader :type

        def initialize(type)
          @type = type
        end

        def [](*args)
          List.new(args, type)
        end

        def coerce(value)
          List.coerce(value, type)
        end

        def pure(val = Undefined, &block)
          value = Undefined.default(val, block)
          List.pure(value, type)
        end
      end

      # List of tasks
      Task = ListBuilder[Task]

      # List of results
      Result = ListBuilder[Result]

      # List of results
      Maybe = ListBuilder[Maybe]

      # List of results
      Try = ListBuilder[Try]

      # List of validation results
      Validated = ListBuilder[Validated]

      # List contructors.
      #
      # @api public
      module Mixin

        # @see Dry::Monads::List
        List = List

        # @see Dry::Monads::List
        L = List

        # List constructor.
        # @return [List]
        def List(value)
          List.coerce(value)
        end
      end
    end
  end
end

require 'dry/monads/traverse'
