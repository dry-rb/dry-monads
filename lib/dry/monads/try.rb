require 'dry/equalizer'

require 'dry/monads/right_biased'
require 'dry/monads/result'
require 'dry/monads/maybe'

module Dry
  module Monads
    # Represents a value which can be either success or a failure (an exception).
    # Use it to wrap code that can raise exceptions.
    #
    # @api public
    class Try
      # @private
      DEFAULT_EXCEPTIONS = [StandardError].freeze

      # @return [Exception] Caught exception
      attr_reader :exception

      class << self
        # Calls the passed in proc object and if successful stores the result in a
        # {Try::Value} monad, but if one of the specified exceptions was raised it stores
        # it in a {Try::Error} monad.
        #
        # @param exceptions [Array<Exception>] list of exceptions to be rescued
        # @param f [Proc] the proc to be called
        # @return [Try::Value, Try::Error]
        def lift(exceptions, f)
          Value.new(exceptions, f.call)
        rescue *exceptions => e
          Error.new(e)
        end

        # Wraps the given value with `Value`.
        #
        # @param value [Object] the value to be stored inside Value
        # @param exceptions [Array<Exception>]
        # @return [Try::Value]
        def pure(value, exceptions = DEFAULT_EXCEPTIONS)
          Value.new(exceptions, value)
        end
      end

      # Returns true for an instance of a {Try::Value} monad.
      def value?
        is_a?(Value)
      end
      alias_method :success?, :value?

      # Returns true for an instance of a {Try::Error} monad.
      def error?
        is_a?(Error)
      end
      alias_method :failure?, :error?

      # Represents a result of a successful execution.
      #
      # @api public
      class Value < Try
        include Dry::Equalizer(:value!, :catchable)
        include RightBiased::Right

        # @private
        attr_reader :catchable

        # @param exceptions [Array<Exception>] list of exceptions to be rescued
        # @param value [Object] the value to be stored in the monad
        def initialize(exceptions, value)
          @catchable = exceptions
          @value = value
        end

        alias_method :bind_call, :bind
        private :bind_call

        # Calls the passed in Proc object with value stored in self
        # and returns the result.
        #
        # If proc is nil, it expects a block to be given and will yield to it.
        #
        # @example
        #   success = Dry::Monads::Try::Value.new(ZeroDivisionError, 10)
        #   success.bind(->(n) { n / 2 }) # => 5
        #   success.bind { |n| n / 0 } # => Try::Error(ZeroDivisionError: divided by 0)
        #
        # @param args [Array<Object>] arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value assumed to be a Proc (callable)
        #                             object and the rest of args will be passed
        #                             to this object along with the internal value
        # @return [Object, Try::Error]
        def bind(*args)
          super
        rescue *catchable => e
          Error.new(e)
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of a Try monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   success = Dry::Monads::Try::Value.new(ZeroDivisionError, 10)
        #   success.fmap(&:succ).fmap(&:succ).value # => 12
        #   success.fmap(&:succ).fmap { |n| n / 0 }.fmap(&:succ).value # => nil
        #
        # @param args [Array<Object>] extra arguments for the block, arguments are being processes
        #                             just as in #bind
        # @return [Try::Value, Try::Error]
        def fmap(*args, &block)
          Value.new(catchable, bind_call(*args, &block))
        rescue *catchable => e
          Error.new(e)
        end

        # @return [Maybe]
        def to_maybe
          Dry::Monads::Maybe(@value)
        end

        # @return [Result::Success]
        def to_result
          Dry::Monads::Result::Success.new(@value)
        end

        # @return [String]
        def to_s
          "Try::Value(#{ @value.inspect })"
        end
        alias_method :inspect, :to_s
      end

      # Represents a result of a failed execution.
      #
      # @api public
      class Error < Try
        include Dry::Equalizer(:exception)
        include RightBiased::Left

        # @param exception [Exception]
        def initialize(exception)
          @exception = exception
        end

        # @return [Maybe::None]
        def to_maybe
          Maybe::None.new(RightBiased::Left.trace_caller)
        end

        # @return [Result::Failure]
        def to_result
          Result::Failure.new(exception, RightBiased::Left.trace_caller)
        end

        # @return [String]
        def to_s
          "Try::Error(#{ exception.class }: #{ exception.message })"
        end
        alias_method :inspect, :to_s

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the first argument.
        #
        # @example
        #   Try(ZeroDivisionError) { 1 / 0 }.or { "zero!" } # => "zero!"
        #
        # @param args [Array<Object>] arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value will be returned
        # @return [Object]
        def or(*args)
          if block_given?
            yield(exception, *args)
          else
            args[0]
          end
        end

        # @param other [Try]
        # @return [Boolean]
        def ===(other)
          Error === other && exception === other.exception
        end
      end

      # A module that can be included for easier access to Try monads.
      #
      # @example
      #   class Foo
      #     include Dry::Monads::Try::Mixin
      #
      #     attr_reader :average
      #
      #     def initialize(total, count)
      #       @average = Try(ZeroDivisionError) { total / count }.value
      #     end
      #   end
      #
      #   Foo.new(10, 2).average # => 5
      #   Foo.new(10, 0).average # => nil
      module Mixin
        # @see Dry::Monads::Try
        Try = Try

        # A convenience wrapper for {Monads::Try.lift}.
        # If no exceptions are provided it falls back to StandardError.
        # In general, relying on this behaviour is not recommended as it can lead to unnoticed
        # bugs and it is always better to explicitly specify a list of exceptions if possible.
        #
        # @param exceptions [Array<Exception>]
        # @return [Try]
        def Try(*exceptions, &f)
          catchable = exceptions.empty? ? Try::DEFAULT_EXCEPTIONS : exceptions.flatten
          Try.lift(catchable, f)
        end

        # A constructor of Value
        # @param value [Object]
        # @param exceptions [Array<Exception>] list of exceptions to be rescued
        # @return [Value]
        def Value(value = Undefined, exceptions = DEFAULT_EXCEPTIONS, &block)
          if value.equal?(Undefined)
            raise ArgumentError, 'No value given' if block.nil?
            Try::Value.new(exceptions, block)
          else
            Try::Value.new(exceptions, value)
          end
        end

        # A constructor of Error
        # @param error [Exception]
        # @param block [Proc] block that may throw an error
        # @return [Error]
        def Error(error = Undefined, &block)
          if error.equal?(Undefined)
            raise ArgumentError, 'No value given' if block.nil?
            Try::Error.new(block)
          else
            Try::Error.new(error)
          end
        end
      end
    end
  end
end
