require 'dry/equalizer'
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

      extend Dry::Core::Deprecations[:'dry-monads']

      class << self
        # Wraps the given value with into a Maybe object.
        #
        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::Some, Maybe::None]
        def coerce(value)
          if value.nil?
            None.instance
          else
            Some.new(value)
          end
        end
        alias_method :lift, :coerce

        # Wraps the given value with `Some`.
        #
        # @param value [Object] the value to be stored inside Some
        # @return [Maybe::Some]
        def pure(value)
          Some.new(value)
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
        include RightBiased::Right
        include Dry::Equalizer(:value!)

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
        # @return [Maybe::Some, Maybe::None] Lifted result, i.e. nil will be mapped to None,
        #                                    other values will be wrapped with Some
        def fmap(*args, &block)
          self.class.lift(bind(*args, &block))
        end

        # @return [String]
        def to_s
          "Some(#{ @value.inspect })"
        end
        alias inspect to_s
      end

      # Represents an absence of a value, i.e. the value nil.
      #
      # @api public
      class None < Maybe
        include RightBiased::Left

        @instance = new.freeze
        singleton_class.send(:attr_reader, :instance)

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

        # A lifted version of `#or`. Applies `Maybe.lift` to the passed value or
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
          Maybe.lift(self.or(*args, &block))
        end

        # @return [String]
        def to_s
          'None'
        end
        alias inspect to_s

        # @api private
        def eql?(other)
          other.is_a?(None)
        end
        alias == eql?

        # @api private
        def hash
          nil.hash
        end
      end

      # A module that can be included for easier access to Maybe monads.
      module Mixin
        Maybe = Maybe
        Some = Some
        None = None

        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::Some, Maybe::None]
        def Maybe(value)
          Maybe.lift(value)
        end

        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::Some]
        def Some(value)
          Some.new(value)
        end

        # @return [Maybe::None]
        def None
          None.instance
        end
      end
    end
  end
end
