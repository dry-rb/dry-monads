require 'dry/equalizer'

require 'dry/monads/undefined'
require 'dry/monads/right_biased'
require 'dry/monads/transformer'
require 'dry/monads/conversion_stubs'
require 'dry/monads/unit'

module Dry
  module Monads
    # Represents an operation which either succeeded or failed.
    #
    # @api public
    class Result
      include Transformer
      include ConversionStubs[:to_maybe, :to_validated]

      # @return [Object] Successful result
      attr_reader :success

      # @return [Object] Error
      attr_reader :failure

      class << self
        # Wraps the given value with Success.
        #
        # @overload pure(value)
        #   @param value [Object]
        #   @return [Result::Success]
        #
        # @overload pure(&block)
        #   @param block [Proc] a block to be wrapped with Success
        #   @return [Result::Success]
        #
        def pure(value = Undefined, &block)
          Success.new(Undefined.default(value, block))
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

        # Transforms to a Failure instance
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

        singleton_class.alias_method(:call, :new)

        # Returns a constructor proc
        #
        # @return [Proc]
        def self.to_proc
          @to_proc ||= method(:new).to_proc
        end

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
        #
        module Constructors

          # Success constructor
          #
          # @overload Success(value)
          #   @param value [Object]
          #   @return [Result::Success]
          #
          # @overload Success(&block)
          #   @param block [Proc] a block to be wrapped with Success
          #   @return [Result::Success]
          #
          def Success(value = Undefined, &block)
            v = Undefined.default(value, block || Unit)
            Success.new(v)
          end

          # Failure constructor
          #
          # @overload Success(value)
          #   @param value [Object]
          #   @return [Result::Failure]
          #
          # @overload Success(&block)
          #   @param block [Proc] a block to be wrapped with Failure
          #   @return [Result::Failure]
          #
          def Failure(value = Undefined, &block)
            v = Undefined.default(value, block || Unit)
            Failure.new(v, RightBiased::Left.trace_caller)
          end
        end

        include Constructors
      end
    end

    extend Result::Mixin::Constructors

    # @see Result::Success
    Success = Result::Success
    # @see Result::Failure
    Failure = Result::Failure

    # Creates a module that has two methods: `Success` and `Failure`.
    # `Success` is identical to {Result::Mixin::Constructors#Success} and Failure
    # rejects values that don't conform the value of the `error`
    # parameter. This is essentially a Result type with the `Failure` part
    # fixed.
    #
    # @example using dry-types
    #   module Types
    #     include Dry::Types.module
    #   end
    #
    #   class Operation
    #     # :user_not_found and :account_not_found are the only
    #     # values allowed as failure results
    #     Error =
    #       Types.Value(:user_not_found) |
    #       Types.Value(:account_not_found)
    #
    #     include Dry::Monads::Result(Error)
    #
    #     def find_account(id)
    #       account = acount_repo.find(id)
    #
    #       account ? Success(account) : Failure(:account_not_found)
    #     end
    #
    #     def find_user(id)
    #       # ...
    #     end
    #   end
    #
    # @param error [#===] the type of allowed failures
    # @return [Module]
    def self.Result(error, **options)
      Result::Fixed[error, **options]
    end

    class Task
      # Converts to Result. Blocks the current thread if required.
      #
      # @return [Result]
      def to_result
        if promise.wait.fulfilled?
          Result::Success.new(promise.value)
        else
          Result::Failure.new(promise.reason, RightBiased::Left.trace_caller)
        end
      end
    end

    class Try
      class Value < Try
        # @return [Result::Success]
        def to_result
          Dry::Monads::Result::Success.new(@value)
        end
      end

      class Error < Try
        # @return [Result::Failure]
        def to_result
          Result::Failure.new(exception, RightBiased::Left.trace_caller)
        end
      end
    end

    class Validated
      class Valid < Validated
        # Converts to Result::Success
        #
        # @return [Result::Success]
        def to_result
          Result.pure(value!)
        end
      end

      class Invalid < Validated
        # Concerts to Result::Failure
        #
        # @return [Result::Failure]
        def to_result
          Result::Failure.new(error, RightBiased::Left.trace_caller)
        end
      end
    end
  end
end
