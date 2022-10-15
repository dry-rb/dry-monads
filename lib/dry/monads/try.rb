# frozen_string_literal: true

module Dry
  module Monads
    # Represents a value which can be either success or a failure (an exception).
    # Use it to wrap code that can raise exceptions.
    #
    # @api public
    class Try
      # @private
      DEFAULT_EXCEPTIONS = [StandardError].freeze

      include ConversionStubs[:to_maybe, :to_result]

      # @return [Exception] Caught exception
      attr_reader :exception

      class << self
        extend Core::Deprecations[:"dry-monads"]

        # Invokes a callable and if successful stores the result in the
        # {Try::Value} type, but if one of the specified exceptions was raised it stores
        # it in a {Try::Error}.
        #
        # @param exceptions [Array<Exception>] list of exceptions to rescue
        # @param f [#call] callable object
        # @return [Try::Value, Try::Error]
        def run(exceptions, f)
          Value.new(exceptions, f.call)
        rescue *exceptions => e
          Error.new(e)
        end
        deprecate :lift, :run

        # Wraps a value with Value
        #
        # @overload pure(value, exceptions = DEFAULT_EXCEPTIONS)
        #   @param value [Object] value for wrapping
        #   @param exceptions [Array<Exceptions>] list of exceptions to rescue
        #   @return [Try::Value]
        #
        # @overload pure(exceptions = DEFAULT_EXCEPTIONS, &block)
        #   @param exceptions [Array<Exceptions>] list of exceptions to rescue
        #   @param block [Proc] value for wrapping
        #   @return [Try::Value]
        #
        def pure(value = Undefined, exceptions = DEFAULT_EXCEPTIONS, &block)
          if value.equal?(Undefined)
            Value.new(DEFAULT_EXCEPTIONS, block)
          elsif block.nil?
            Value.new(exceptions, value)
          else
            Value.new(value, block)
          end
        end

        # Safely runs a block
        #
        # @example using Try with [] and a block (Ruby 2.5+)
        #   include Dry::Monads::Try::Mixin
        #
        #   def safe_db_call
        #     Try[DatabaseError] { db_call }
        #   end
        #
        # @param exceptions [Array<Exception>]
        # @return [Try::Value,Try::Error]
        def [](*exceptions, &block)
          raise ArgumentError, "At least one exception type required" if exceptions.empty?

          run(exceptions, block)
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

      # Returns self.
      #
      # @return [Try::Value, Try::Error]
      def to_monad
        self
      end

      # Represents a result of a successful execution.
      #
      # @api public
      class Value < Try
        include Dry::Equalizer(:value!, :catchable)
        include RightBiased::Right

        # @return [Array<Exception>] List of exceptions to rescue
        attr_reader :catchable

        # @param exceptions [Array<Exception>] list of exceptions to be rescued
        # @param value [Object] the value to be stored in the monad
        def initialize(exceptions, value)
          super()

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
        def bind(...)
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
        def fmap(...)
          Value.new(catchable, bind_call(...))
        rescue *catchable => e
          Error.new(e)
        end

        # @return [String]
        def to_s
          if Unit.equal?(@value)
            "Try::Value()"
          else
            "Try::Value(#{@value.inspect})"
          end
        end
        alias_method :inspect, :to_s

        # Ignores values and returns self, see {Try::Error#recover}
        #
        # @param errors [Class] List of Exception subclasses
        #
        # @return [Try::Value]
        def recover(*_errors)
          self
        end
      end

      # Represents a result of a failed execution.
      #
      # @api public
      class Error < Try
        include Dry::Equalizer(:exception)
        include RightBiased::Left

        singleton_class.alias_method(:call, :new)

        # @param exception [Exception]
        def initialize(exception)
          super()

          @exception = exception
        end

        # @return [String]
        def to_s
          "Try::Error(#{exception.class}: #{exception.message})"
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

        # Acts in a similar way to `rescue`. It checks if
        # {exception} is one of {errors} and yields the block if so.
        #
        # @param errors [Class] List of Exception subclasses
        #
        # @return [Try::Value]
        def recover(*errors)
          if errors.empty?
            classes = DEFAULT_EXCEPTIONS
          else
            classes = errors
          end

          if classes.any? { _1 === exception }
            Value.new([exception.class], yield(exception))
          else
            self
          end
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

        # @private
        module Constructors
          # A convenience wrapper for {Monads::Try.run}.
          # If no exceptions are provided it falls back to StandardError.
          # In general, relying on this behaviour is not recommended as it can lead to unnoticed
          # bugs and it is always better to explicitly specify a list of exceptions if possible.
          #
          # @param exceptions [Array<Exception>]
          # @return [Try]
          def Try(*exceptions, &f)
            catchable = exceptions.empty? ? DEFAULT_EXCEPTIONS : exceptions.flatten
            Try.run(catchable, f)
          end
        end

        include Constructors

        # Value constructor
        #
        # @overload Value(value)
        #   @param value [Object]
        #   @return [Try::Value]
        #
        # @overload Value(&block)
        #   @param block [Proc] a block to be wrapped with Value
        #   @return [Try::Value]
        #
        def Value(value = Undefined, exceptions = DEFAULT_EXCEPTIONS, &block)
          v = Undefined.default(value, block)
          raise ArgumentError, "No value given" if !value.nil? && v.nil?

          Try::Value.new(exceptions, v)
        end

        # Error constructor
        #
        # @overload Error(value)
        #   @param error [Exception]
        #   @return [Try::Error]
        #
        # @overload Error(&block)
        #   @param block [Proc] a block to be wrapped with Error
        #   @return [Try::Error]
        #
        def Error(error = Undefined, &block)
          v = Undefined.default(error, block)
          raise ArgumentError, "No value given" if v.nil?

          Try::Error.new(v)
        end
      end
    end

    require "dry/monads/registry"
    register_mixin(:try, Try::Mixin)
  end
end
