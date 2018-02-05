require 'dry/equalizer'
require 'dry/core/constants'

require 'dry/monads/right_biased'
require 'dry/monads/transformer'
require 'dry/monads/maybe'

module Dry
  module Monads
    # Represents an operation which either succeeded or failed.
    #
    # @api public
    class Result
      include Transformer

      # @return [Object] Successful result
      attr_reader :success

      # @return [Object] Error
      attr_reader :failure

      class << self
        # Wraps the given value with Success
        #
        # @param value [Object] value to be wrapped with Success
        # @param block [Object] block to be wrapped with Success
        # @return [Result::Success]
        def pure(value = Undefined, &block)
          if value.equal?(Undefined)
            Success.new(block)
          else
            Success.new(value)
          end
        end
      end

      # Returns self, added to keep the interface compatible with other monads.
      #
      # @return [Result::Success, Result::Failure]
      def to_result
        self
      end

      # Returns self.
      #
      # @return [Result::Success, Result::Failure]
      def to_monad
        self
      end

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

        # Returns true
        def success?
          true
        end

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
          Failure.new(@value, RightBiased::Left.trace_caller)
        end
      end

      # Represents a value of a failed operation.
      #
      # @api public
      class Failure < Result
        include RightBiased::Left
        include Dry::Equalizer(:failure)

        # Line where the value was constructed
        #
        # @return [String]
        # @api public
        attr_reader :trace

        # @param value [Object] failure value
        # @param trace [String] caller line
        def initialize(value, trace = RightBiased::Left.trace_caller)
          @value = value
          @trace = trace
        end

        # @private
        def failure
          @value
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

        # Returns false
        def success?
          false
        end

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
          Maybe::None.new(trace)
        end

        # Transform to a Success instance
        #
        # @return [Result::Success]
        def flip
          Success.new(@value)
        end

        # @see RightBiased::Left#value_or
        def value_or(val = nil)
          if block_given?
            yield(@value)
          else
            val
          end
        end

        # @param other [Result]
        # @return [Boolean]
        def ===(other)
          Failure === other && failure === other.failure
        end
      end

      # A module that can be included for easier access to Result monads.
      #
      # @api public
      module Mixin
        # @see Result::Success
        Success = Result::Success
        # @see Result::Failure
        Failure = Result::Failure

        # Value constructors
        module Constructors
          # @param value [Object] the value to be stored in the monad
          # @return [Result::Success]
          # @api public
          def Success(value = Dry::Core::Constants::Undefined, &block)
            if value.equal?(Dry::Core::Constants::Undefined)
              raise ArgumentError, 'No value given' if block.nil?
              Success.new(block)
            else
              Success.new(value)
            end
          end

          # @param value [Object] the value to be stored in the monad
          # @return [Result::Failure]
          # @api public
          def Failure(value = Dry::Core::Constants::Undefined, &block)
            if value.equal?(Dry::Core::Constants::Undefined)
              raise ArgumentError, 'No value given' if block.nil?
              Failure.new(block, RightBiased::Left.trace_caller)
            else
              Failure.new(value, RightBiased::Left.trace_caller)
            end
          end
        end

        include Constructors
      end
    end
  end
end
