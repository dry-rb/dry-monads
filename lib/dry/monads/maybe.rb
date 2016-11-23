require 'dry/equalizer'

require_relative 'value_or'

module Dry
  module Monads
    # Represents a value which can exist or not, i.e. it could be nil.
    #
    # @api public
    class Maybe
      include Dry::Equalizer(:value)

      # Lifts the given value into Maybe::None or Maybe::Some monad.
      #
      # @param value [Object] the value to be stored in the monad
      # @return [Maybe::Some, Maybe::None]
      def self.lift(value)
        if value.nil?
          None.instance
        else
          Some.new(value)
        end
      end

      # Returns true for an instance of a {Maybe::None} monad.
      def none?
        is_a?(None)
      end

      # Returns true for an instance of a {Maybe::Some} monad.
      def some?
        is_a?(Some)
      end

      # Returns self, added to keep the interface compatible with that of Either monad types.
      #
      # @return [Maybe::Some, Maybe::None]
      def to_maybe
        self
      end

      # Represents a value that is present, i.e. not nil.
      #
      # @api public
      class Some < Maybe
        include ValueOrPositive

        attr_reader :value

        def initialize(value)
          raise ArgumentError, 'nil cannot be some' if value.nil?
          @value = value
        end

        # Calls the passed in Proc object with value stored in self
        # and returns the result.
        #
        # If proc is nil, it expects a block to be given and will yield to it.
        #
        # @example
        #   Dry::Monads.Some(4).bind(&:succ) # => 5
        #
        # @param [Array<Object>] args arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value assumed to be a Proc (callable)
        #                             object and the rest of args will be passed
        #                             to this object along with the internal value
        # @return [Object] result of calling proc or block on the internal value
        def bind(*args)
          if block_given?
            yield(value, *args)
          else
            args[0].call(value, *args.drop(1))
          end
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of Maybe::Some monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Some(4).fmap(&:succ).fmap(->(n) { n**2 }) # => Some(25)
        #
        # @param [Array<Object>] args arguments will be transparently passed through to #bind
        # @return [Maybe::Some, Maybe::None] Lifted result, i.e. nil will be mapped to None,
        #                                    other values will be wrapped with Some
        def fmap(*args, &block)
          self.class.lift(bind(*args, &block))
        end

        # Ignores arguments and returns value. It exists to keep the interface
        # identical to that of {Maybe::None}.
        #
        # @return [Object]
        def or(*)
          value
        end

        # @return [String]
        def to_s
          "Some(#{value.inspect})"
        end
        alias inspect to_s
      end

      # Represents an absence of a value, i.e. the value nil.
      #
      # @api public
      class None < Maybe
        include ValueOrNegative

        @instance = new
        singleton_class.send(:attr_reader, :instance)

        # @return [nil]
        def value
          nil
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {Maybe::Some}.
        #
        # @return [Maybe::None]
        def bind(*)
          self
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {Maybe::Some}.
        #
        # @return [Maybe::None]
        def fmap(*)
          self
        end

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the parameter val.
        #
        # @example
        #   Dry::Monads.None.or('no value') # => "no value"
        #   Dry::Monads.None.or { Time.now } # => current time
        #
        # @param val [Object, nil]
        # @return [Object]
        def or(*args)
          if block_given?
            yield(*args)
          else
            args[0]
          end
        end

        # @return [String]
        def to_s
          'None'
        end
        alias inspect to_s
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
