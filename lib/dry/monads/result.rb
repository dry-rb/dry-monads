# frozen_string_literal: true

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

        # Shortcut for Success([...])
        #
        #  @example
        #    include Dry::Monads[:result]
        #
        #    def call
        #      Success[200, {}, ['ok']] # => Success([200, {}, ['ok']])
        #    end
        #
        # @api public
        def self.[](*value)
          new(value)
        end

        alias_method :success, :value!

        # @param value [Object] a value of a successful operation
        def initialize(value)
          super()
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
        def fmap(...)
          Success.new(bind(...))
        end

        # Returns result of applying first function to the internal value.
        #
        # @example
        #   Dry::Monads.Success(1).either(-> x { x + 1 }, -> x { x + 2 }) # => 2
        #
        # @param f [#call] Function to apply
        # @param _ [#call] Ignored
        # @return [Any] Return value of `f`
        def either(f, _)
          f.(success)
        end

        # @return [String]
        def to_s
          if Unit.equal?(@value)
            "Success()"
          else
            "Success(#{@value.inspect})"
          end
        end
        alias_method :inspect, :to_s

        # Transforms to a Failure instance
        #
        # @return [Result::Failure]
        def flip
          Failure.new(@value, RightBiased::Left.trace_caller)
        end

        # Ignores values and returns self, see {Failure#alt_map}
        #
        # @return [Result::Success]
        def alt_map(_ = nil)
          self
        end
      end

      # Represents a value of a failed operation.
      #
      # @api public
      class Failure < Result
        include RightBiased::Left
        include Dry::Equalizer(:failure)

        singleton_class.alias_method(:call, :new)

        # Shortcut for Failure([...])
        #
        #  @example
        #    include Dry::Monads[:result]
        #
        #    def call
        #      Failure[:error, :not_found] # => Failure([:error, :not_found])
        #    end
        #
        # @api public
        def self.[](*value)
          new(value, RightBiased::Left.trace_caller)
        end

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
          super()
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
        #   Dry::Monads.Failure(ArgumentError.new('error message')).or(&:message)
        #   # => "error message"
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

        # A lifted version of `#or`. Wraps the passed value or the block
        # result with Result::Success.
        #
        # @example
        #   Dry::Monads.Failure.new('no value').or_fmap('value') # => Success("value")
        #   Dry::Monads.Failure.new('no value').or_fmap { 'value' } # => Success("value")
        #
        # @param args [Array<Object>] arguments will be passed to the underlying `#or` call
        # @return [Result::Success] Wrapped value
        def or_fmap(...)
          Success.new(self.or(...))
        end

        # @return [String]
        def to_s
          if Unit.equal?(@value)
            "Failure()"
          else
            "Failure(#{@value.inspect})"
          end
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

        # Returns result of applying second function to the internal value.
        #
        # @example
        #   Dry::Monads.Failure(1).either(-> x { x + 1 }, -> x { x + 2 }) # => 3
        #
        # @param _ [#call] Ignored
        # @param g [#call] Function to call
        # @return [Any] Return value of `g`
        def either(_, g)
          g.(failure)
        end

        # Lifts a block/proc over Failure
        #
        # @overload alt_map(proc)
        #   @param proc [#call]
        #   @return [Result::Failure]
        #
        # @overload alt_map
        #   @param block [Proc]
        #   @return [Result::Failure]
        #
        def alt_map(proc = Undefined, &block)
          f = Undefined.default(proc, block)
          self.class.new(f.(failure), RightBiased::Left.trace_caller)
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

    class Maybe
      class Some < Maybe
        # Converts to Sucess(value!)
        #
        # @param fail [#call] Fallback value
        # @param block [Proc] Fallback block
        # @return [Success<Any>]
        def to_result(_fail = Unit)
          Result::Success.new(@value)
        end
      end

      class None < Maybe
        # Converts to Failure(fallback_value)
        #
        # @param fail [#call] Fallback value
        # @param block [Proc] Fallback block
        # @return [Failure<Any>]
        def to_result(fail = Unit)
          if block_given?
            Result::Failure.new(yield)
          else
            Result::Failure.new(fail)
          end
        end
      end
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
        # Converts to Result::Failure
        #
        # @return [Result::Failure]
        def to_result
          Result::Failure.new(error, RightBiased::Left.trace_caller)
        end
      end
    end

    require "dry/monads/registry"
    register_mixin(:result, Result::Mixin)
  end
end
