# frozen_string_literal: true

module Dry
  module Monads
    # Represents a value which can exist or not, i.e. it could be nil.
    #
    # @api public
    class Maybe
      include Transformer
      extend Core::ClassAttributes

      defines :warn_on_implicit_nil_coercion
      warn_on_implicit_nil_coercion true

      class << self
        extend Core::Deprecations[:"dry-monads"]

        # Wraps the given value with into a Maybe object.
        #
        # @param value [Object] value to be stored in the monad
        # @return [Maybe::Some, Maybe::None]
        def coerce(value)
          if value.nil?
            None.instance
          else
            Some.new(value)
          end
        end
        deprecate :lift, :coerce

        # Wraps the given value with `Some`.
        #
        # @param value [Object] value to be wrapped with Some
        # @param block [Object] block to be wrapped with Some
        # @return [Maybe::Some]
        def pure(value = Undefined, &block)
          Some.new(Undefined.default(value, block))
        end

        # Reutrns a Some wrapper converted to a block
        #
        # @return [Proc]
        def to_proc
          @to_proc ||= method(:coerce).to_proc
        end
      end

      # Returns true for an instance of a {Maybe::None} monad.
      def none?
        is_a?(None)
      end
      alias_method :failure?, :none?

      # Returns true for an instance of a {Maybe::Some} monad.
      def some?
        is_a?(Some)
      end
      alias_method :success?, :some?

      # Returns self, added to keep the interface compatible with that of Either monad types.
      #
      # @return [Maybe::Some, Maybe::None]
      def to_maybe
        self
      end

      # Returns self.
      #
      # @return [Maybe::Some, Maybe::None]
      def to_monad
        self
      end

      # Returns the Maybe monad.
      # This is how we're doing polymorphism in Ruby 😕
      #
      # @return [Monad]
      def monad
        Maybe
      end

      # Represents a value that is present, i.e. not nil.
      #
      # @api public
      class Some < Maybe
        include Dry::Equalizer(:value!)
        include RightBiased::Right

        # Shortcut for Some([...])
        #
        #  @example
        #    include Dry::Monads[:maybe]
        #
        #    def call
        #      Some[200, {}, ['ok']] # => Some([200, {}, ['ok']])
        #    end
        #
        # @api public
        def self.[](*value)
          new(value)
        end

        def initialize(value = Undefined)
          raise ArgumentError, "nil cannot be some" if value.nil?

          super()

          @value = Undefined.default(value, Unit)
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of Maybe::Some monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Some(4).fmap(&:succ).fmap(->(n) { n**2 }) # => Some(25)
        #
        # @param args [Array<Object>] arguments will be transparently passed through to #bind
        # @return [Maybe::Some, Maybe::None] Wrapped result, i.e. nil will be mapped to None,
        #                                    other values will be wrapped with Some
        def fmap(...)
          next_value = bind(...)

          if next_value.nil?
            if self.class.warn_on_implicit_nil_coercion
              Core::Deprecations.warn(
                "Block passed to Some#fmap returned `nil` and was chained to None. "\
                "This is literally an unlawful behavior and it will not be supported in "\
                "dry-monads 2. \nPlease, replace `.fmap` with `.maybe` in places where you "\
                "expect `nil` as block result.\n"\
                "You can opt out of these warnings with\n"\
                "Dry::Monads::Maybe.warn_on_implicit_nil_coercion false",
                uplevel: 0,
                tag: :"dry-monads"
              )
            end
            Monads.None()
          else
            Some.new(next_value)
          end
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of the Maybe monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Some(4).maybe(&:succ).maybe(->(n) { n**2 }) # => Some(25)
        #   Dry::Monads.Some(4).maybe(&:succ).maybe(->(_) { nil }) # => None()
        #
        # @param args [Array<Object>] arguments will be transparently passed through to #bind
        # @return [Maybe::Some, Maybe::None] Wrapped result, i.e. nil will be mapped to None,
        #                                    other values will be wrapped with Some
        def maybe(...)
          Maybe.coerce(bind(...))
        end

        # Accepts a block and runs it against the wrapped value.
        # If the block returns a trurhy value the result is self,
        # otherwise None. If no block is given, the value serves
        # and its result.
        #
        # @param with [#call] positional block
        # @param block [Proc] block
        #
        # @return [Maybe::None, Maybe::Some]
        def filter(with = Undefined, &block)
          block = Undefined.default(with, block || IDENTITY)

          if block.(@value)
            self
          else
            Monads.None()
          end
        end

        # @return [String]
        def to_s
          if Unit.equal?(@value)
            "Some()"
          else
            "Some(#{@value.inspect})"
          end
        end
        alias_method :inspect, :to_s
      end

      # Represents an absence of a value, i.e. the value nil.
      #
      # @api public
      class None < Maybe
        include RightBiased::Left

        @instance = new.freeze
        singleton_class.attr_reader(:instance)

        # @api private
        def self.method_missing(m, *) # rubocop:disable Style/MissingRespondToMissing
          if (instance.methods(true) - methods(true)).include?(m)
            raise ConstructorNotAppliedError.new(m, :None)
          else
            super
          end
        end
        private_class_method :method_missing

        # Line where the value was constructed
        #
        # @return [String]
        attr_reader :trace

        def initialize(trace = RightBiased::Left.trace_caller)
          super()
          @trace = trace
        end

        # @!method maybe(*args, &block)
        #   Alias of fmap, returns self back
        alias_method :maybe, :fmap

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the parameter val.
        #
        # @example
        #   Dry::Monads.None.or('no value') # => "no value"
        #   Dry::Monads.None.or { Time.now } # => current time
        #
        # @param args [Array<Object>] if no block given the first argument will be returned
        #                             otherwise arguments will be transparently passed to the block
        # @return [Object]
        def or(*args)
          if block_given?
            yield(*args)
          else
            args[0]
          end
        end

        # A lifted version of `#or`. Applies `Maybe.coerce` to the passed value or
        # to the block result.
        #
        # @example
        #   Dry::Monads.None.or_fmap('no value') # => Some("no value")
        #   Dry::Monads.None.or_fmap { Time.now } # => Some(current time)
        #
        # @param args [Array<Object>] arguments will be passed to the underlying `#or` call
        # @return [Maybe::Some, Maybe::None] Lifted `#or` result, i.e. nil will be mapped to None,
        #                                    other values will be wrapped with Some
        def or_fmap(...)
          Maybe.coerce(self.or(...))
        end

        # @return [String]
        def to_s
          "None"
        end
        alias_method :inspect, :to_s

        # @api private
        def eql?(other)
          other.is_a?(None)
        end
        alias_method :==, :eql?

        # @private
        def hash
          None.instance.object_id
        end

        # Pattern matching
        #
        # @example
        #   case Some(:foo)
        #   in Some(Integer) then ...
        #   in Some(:bar) then ...
        #   in None() then ...
        #   end
        #
        # @api private
        def deconstruct
          EMPTY_ARRAY
        end

        # @see Maybe::Some#filter
        #
        # @return [Maybe::None]
        def filter(_ = Undefined)
          self
        end
      end

      # A module that can be included for easier access to Maybe monads.
      module Mixin
        # @see Dry::Monads::Maybe
        Maybe = Maybe
        # @see Maybe::Some
        Some = Some
        # @see Maybe::None
        None = None

        # @private
        module Constructors
          # @param value [Object] the value to be stored in the monad
          # @return [Maybe::Some, Maybe::None]
          def Maybe(value)
            Maybe.coerce(value)
          end

          # Some constructor
          #
          # @overload Some(value)
          #   @param value [Object] any value except `nil`
          #   @return [Maybe::Some]
          #
          # @overload Some(&block)
          #   @param block [Proc] a block to be wrapped with Some
          #   @return [Maybe::Some]
          #
          def Some(value = Undefined, &block)
            v = Undefined.default(value, block || Unit)
            Some.new(v)
          end

          # @return [Maybe::None]
          def None
            None.new(RightBiased::Left.trace_caller)
          end
        end

        include Constructors
      end

      # Utilities for working with hashes storing Maybe values
      module Hash
        # Traverses a hash with maybe values. If any value is None then None is returned
        #
        # @example
        #   Maybe::Hash.all(foo: Some(1), bar: Some(2)) # => Some(foo: 1, bar: 2)
        #   Maybe::Hash.all(foo: Some(1), bar: None())  # => None()
        #   Maybe::Hash.all(foo: None(), bar: Some(2))  # => None()
        #
        # @param hash [::Hash<Object,Maybe>]
        # @return [Maybe<::Hash>]
        #
        def self.all(hash, trace = RightBiased::Left.trace_caller)
          result = hash.each_with_object({}) do |(key, value), output|
            if value.some?
              output[key] = value.value!
            else
              return None.new(trace)
            end
          end

          Some.new(result)
        end

        # Traverses a hash with maybe values. Some values are unwrapped, keys with
        # None values are removed
        #
        # @example
        #   Maybe::Hash.filter(foo: Some(1), bar: Some(2)) # => { foo: 1, bar: 2 }
        #   Maybe::Hash.filter(foo: Some(1), bar: None())  # => { foo: 1 }
        #   Maybe::Hash.filter(foo: None(), bar: Some(2))  # => { bar: 2 }
        #
        # @param hash [::Hash<Object,Maybe>]
        # @return [::Hash]
        #
        def self.filter(hash)
          hash.each_with_object({}) do |(key, value), output|
            output[key] = value.value! if value.some?
          end
        end
      end
    end

    extend Maybe::Mixin::Constructors

    # @see Maybe::Some
    Some = Maybe::Some
    # @see Maybe::None
    None = Maybe::None

    class Result
      class Success < Result
        extend Core::Deprecations[:"dry-monads"]

        # @return [Maybe]
        def to_maybe
          warn "Success(nil) transformed to None" if @value.nil?
          ::Dry::Monads::Maybe(@value)
        end
      end

      class Failure < Result
        # @return [Maybe::None]
        def to_maybe
          Maybe::None.new(trace)
        end
      end
    end

    class Task
      # Converts to Maybe. Blocks the current thread if required.
      #
      # @return [Maybe]
      def to_maybe
        if promise.wait.fulfilled?
          Maybe::Some.new(promise.value)
        else
          Maybe::None.new(RightBiased::Left.trace_caller)
        end
      end
    end

    class Try
      class Value < Try
        # @return [Maybe]
        def to_maybe
          Dry::Monads::Maybe(@value)
        end
      end

      class Error < Try
        # @return [Maybe::None]
        def to_maybe
          Maybe::None.new(RightBiased::Left.trace_caller)
        end
      end
    end

    class Validated
      class Valid < Validated
        # Converts to Maybe::Some
        #
        # @return [Maybe::Some]
        def to_maybe
          Maybe.pure(value!)
        end
      end

      class Invalid < Validated
        # Converts to Maybe::None
        #
        # @return [Maybe::None]
        def to_maybe
          Maybe::None.new(RightBiased::Left.trace_caller)
        end
      end
    end

    require "dry/monads/registry"
    register_mixin(:maybe, Maybe::Mixin)
  end
end
