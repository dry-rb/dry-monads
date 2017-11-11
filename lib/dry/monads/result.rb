require 'dry/equalizer'

require 'dry/monads/right_biased'
require 'dry/monads/transformer'

module Dry
  module Monads
    # Represents an operation which either succeeded or failed.
    #
    # @api public
    class Result
      include Transformer

      attr_reader :success, :failure

      class << self
        # Wraps the given value with Success
        #
        # @param value [Object] the value to be stored inside Success
        # @return [Result::Success]
        def pure(value)
          Success.new(value)
        end
      end

      # Returns self, added to keep the interface compatible with other monads.
      #
      # @return [Result::Success, Result::Failure]
      def to_result
        self
      end
      alias_method :to_either, :to_result

      # Returns the Result monad.
      # This is how we're doing polymorphism in Ruby 😕
      #
      # @return [Monad]
      def monad
        Result
      end

      # Represents a value of a successful operation.
      #
      # @api public
      class Success < Result
        include RightBiased::Right
        include Dry::Equalizer(:value!)

        alias_method :success, :value!

        # @param value [Object] a value of a successful operation
        def initialize(value)
          @value = value
        end

        # Apply the second function to value.
        #
        # @api public
        def result(_, f)
          f.(@value)
        end

        # Returns false
        def failure?
          false
        end
        alias_method :left?, :failure?

        # Returns true
        def success?
          true
        end
        alias_method :right?, :success?

        # Does the same thing as #bind except it also wraps the value
        # in an instance of Result::Success monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Success(4).fmap(&:succ).fmap(->(n) { n**2 }) # => Success(25)
        #
        # @param args [Array<Object>] arguments will be transparently passed through to #bind
        # @return [Result::Success]
        def fmap(*args, &block)
          Success.new(bind(*args, &block))
        end

        # @return [String]
        def to_s
          "Success(#{ @value.inspect })"
        end
        alias_method :inspect, :to_s

        # @return [Maybe::Some]
        def to_maybe
          Kernel.warn 'Success(nil) transformed to None' if @value.nil?
          Dry::Monads::Maybe(@value)
        end

        # Transform to a Failure instance
        #
        # @return [Result::Failure]
        def flip
          Failure.new(@value)
        end
      end

      # Represents a value of a failed operation.
      #
      # @api public
      class Failure < Result
        include RightBiased::Left
        include Dry::Equalizer(:failure)

        # @api private
        def failure
          @value
        end
        alias_method :left, :failure

        # @param value [Object] a value in an error state
        def initialize(value)
          @value = value
        end

        # Apply the first function to value.
        #
        # @api public
        def result(f, _)
          f.(@value)
        end

        # Returns true
        def failure?
          true
        end
        alias_method :left?, :failure?

        # Returns false
        def success?
          false
        end
        alias_method :right?, :success?

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the first argument.
        #
        # @example
        #   Dry::Monads.Failure(ArgumentError.new('error message')).or(&:message) # => "error message"
        #
        # @param args [Array<Object>] arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value will be returned
        # @return [Object]
        def or(*args)
          if block_given?
            yield(@value, *args)
          else
            args[0]
          end
        end

        # A lifted version of `#or`. Wraps the passed value or the block result with Result::Success.
        #
        # @example
        #   Dry::Monads.Failure.new('no value').or_fmap('value') # => Success("value")
        #   Dry::Monads.Failure.new('no value').or_fmap { 'value' } # => Success("value")
        #
        # @param args [Array<Object>] arguments will be passed to the underlying `#or` call
        # @return [Result::Success] Wrapped value
        def or_fmap(*args, &block)
          Success.new(self.or(*args, &block))
        end

        # @return [String]
        def to_s
          "Failure(#{ @value.inspect })"
        end
        alias_method :inspect, :to_s

        # @return [Maybe::None]
        def to_maybe
          Maybe::None.instance
        end

        # Transform to a Success instance
        #
        # @return [Result::Success]
        def flip
          Success.new(@value)
        end

        # @see Dry::Monads::RightBiased::Left#value_or
        def value_or(val = nil)
          if block_given?
            yield(@value)
          else
            val
          end
        end
      end

      # A module that can be included for easier access to Result monads.
      module Mixin
        Success = Dry::Monads::Result::Success
        Failure = Dry::Monads::Result::Failure

        # @param value [Object] the value to be stored in the monad
        # @return [Result::Success]
        def Success(value)
          Success.new(value)
        end
        alias_method :Right, :Success

        # @param value [Object] the value to be stored in the monad
        # @return [Result::Failure]
        def Failure(value)
          Failure.new(value)
        end
        alias_method :Left, :Failure
      end
    end

    Either = Result
    Result::Right = Result::Success
    Result::Left = Result::Failure
  end
end
