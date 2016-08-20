module Dry
  module Monads
    # Represents a value which can be either success or a failure (an exception).
    # Use it to wrap code that can raise exceptions.
    #
    # @api public
    class Try
      attr_reader :exception, :value

      # Calls the passed in proc object and if successful stores the result in a
      # {Try::Success} monad, but if one of the specified exceptions was raised it stores
      # it in a {Try::Failure} monad.
      #
      # @param exceptions [Array<Exception>] list of exceptions to be rescued
      # @param f [Proc] the proc to be called
      # @return [Try::Success, Try::Failure]
      def self.lift(exceptions, f)
        Success.new(exceptions, f.call)
      rescue *exceptions => e
        Failure.new(e)
      end

      # Returns true for an instance of a {Try::Success} monad.
      def success?
        is_a? Success
      end

      # Returns true for an instance of a {Try::Failure} monad.
      def failure?
        is_a? Failure
      end

      # Represents a result of a successful execution.
      #
      # @api public
      class Success < Try
        include Dry::Equalizer(:value, :catchable)
        attr_reader :catchable

        # @param exceptions [Array<Exception>] list of exceptions to be rescued
        # @param value [Object] the value to be stored in the monad
        def initialize(exceptions, value)
          @catchable = exceptions
          @value = value
        end

        # Calls the passed in Proc object with value stored in self
        # and returns the result.
        #
        # If proc is nil, it expects a block to be given and will yield to it.
        #
        # @example
        #   success = Dry::Monads::Try::Success.new(ZeroDivisionError, 10)
        #   success.bind(->(n) { n / 2 }) # => 5
        #   success.bind { |n| n / 0 } # => Try::Failure(ZeroDivisionError: divided by 0)
        #
        # @param [Array<Object>] args arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value assumed to be a Proc (callable)
        #                             object and the rest of args will be passed
        #                             to this object along with the internal value
        # @return [Object, Try::Failure]
        def bind(*args)
          if block_given?
            yield(value, *args)
          else
            args[0].call(value, *args.drop(1))
          end
        rescue *catchable => e
          Failure.new(e)
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of a Try monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   success = Dry::Monads::Try::Success.new(ZeroDivisionError, 10)
        #   success.fmap(&:succ).fmap(&:succ).value # => 12
        #   success.fmap(&:succ).fmap { |n| n / 0 }.fmap(&:succ).value # => nil
        #
        # @param [Array<Object>] args extra arguments for the block, arguments are being processes
        #                             just as in #bind
        # @return [Try::Success, Try::Failure]
        def fmap(*args, &block)
          if block
            Try.lift(catchable, -> { block.call(value, *args) })
          else
            Try.lift(catchable, -> { args[0].call(value, *args.drop(1)) })
          end
        end

        # @return [Maybe]
        def to_maybe
          Dry::Monads::Maybe(value)
        end

        # @return [Either::Right]
        def to_either
          Dry::Monads::Right(value)
        end

        # @return [String]
        def to_s
          "Try::Success(#{value.inspect})"
        end
        alias inspect to_s
      end

      # Represents a result of a failed execution.
      #
      # @api public
      class Failure < Try
        include Dry::Equalizer(:exception)

        # @param exception [Exception]
        def initialize(exception)
          @exception = exception
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {Try::Success}.
        #
        # @return [Try::Failure]
        def bind(*)
          self
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {Try::Success}.
        #
        # @return [Try::Failure]
        def fmap(*)
          self
        end

        # @return [Maybe::None]
        def to_maybe
          Dry::Monads::None()
        end

        # @return [Either::Left]
        def to_either
          Dry::Monads::Left(exception)
        end

        # @return [String]
        def to_s
          "Try::Failure(#{exception.class}: #{exception.message})"
        end
        alias inspect to_s
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
        Try = Try

        # A convenience wrapper for {Try.lift}.
        # If no exceptions are provided it falls back to StandardError.
        # In general, relying on this behaviour is not recommended as it can lead to unnoticed
        # bugs and it is always better to explicitly specify a list of exceptions if possible.
        def Try(*exceptions, &f)
          catchable = exceptions.any? ? exceptions.flatten : [StandardError]
          Try.lift(catchable, f)
        end
      end
    end
  end
end
