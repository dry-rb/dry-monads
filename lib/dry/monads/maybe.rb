require 'dry/equalizer'
require 'dry/core/constants'
require 'dry/core/deprecations'

require 'dry/monads/right_biased'
require 'dry/monads/transformer'

module Dry
  module Monads
    # Represents a value which can exist or not, i.e. it could be nil.
    #
    # @api public
    class Maybe
      include Transformer

      class << self
        extend Dry::Core::Deprecations[:'dry-monads']

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

        def initialize(value)
          raise ArgumentError, 'nil cannot be some' if value.nil?
          @value = value
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
        def fmap(*args, &block)
          self.class.coerce(bind(*args, &block))
        end

        # @return [String]
        def to_s
          "Some(#{ @value.inspect })"
        end
        alias_method :inspect, :to_s
      end

      # Represents an absence of a value, i.e. the value nil.
      #
      # @api public
      class None < Maybe
        include RightBiased::Left

        @instance = new.freeze
        singleton_class.send(:attr_reader, :instance)

        # Line where the value was constructed
        #
        # @return [String]
        attr_reader :trace

        def initialize(trace = RightBiased::Left.trace_caller)
          @trace = trace
        end

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
        def or_fmap(*args, &block)
          Maybe.coerce(self.or(*args, &block))
        end

        # @return [String]
        def to_s
          'None'
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
            v = Undefined.default(value, block)
            raise ArgumentError, 'No value given' if !value.nil? && v.nil?
            Some.new(v)
          end

          # @return [Maybe::None]
          def None
            None.new(RightBiased::Left.trace_caller)
          end
        end

        include Constructors
      end
    end

    class Result
      class Success < Result
        # @return [Maybe::Some]
        def to_maybe
          Kernel.warn 'Success(nil) transformed to None' if @value.nil?
          Dry::Monads::Maybe(@value)
        end
      end

      class Failure < Result
        # @return [Maybe::None]
        def to_maybe
          Maybe::None.new(trace)
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
end
