module Dry
  module Monads
    class Try
      attr_reader :exception, :value

      def self.lift(exceptions, f)
        Success.new(exceptions, f.call)
      rescue *exceptions => e
        Failure.new(e)
      end

      def success?
        is_a? Success
      end

      def failure?
        is_a? Failure
      end

      class Success < Try
        attr_reader :catchable

        def initialize(exceptions, value)
          @catchable = exceptions
          @value = value
        end

        def bind(proc = nil)
          if proc
            proc.call(value)
          else
            yield(@value)
          end
        rescue *catchable => e
          Failure.new(e)
        end

        def fmap(proc = nil, &block)
          Try.lift(catchable, -> { (block || proc).call(@value) })
        end

        def ==(other)
          other.is_a?(Success) && @value == other.value && @catchable == other.catchable
        end

        def to_maybe
          Dry::Monads::Maybe(@value)
        end

        def to_either
          Dry::Monads::Right(@value)
        end

        def to_s
          "Try::Success(#{value.inspect})"
        end
        alias inspect to_s
      end

      class Failure < Try
        def initialize(exception)
          @exception = exception
        end

        def bind(_f = nil)
          self
        end

        def fmap(_f = nil)
          self
        end

        def to_maybe
          Dry::Monads::None()
        end

        def to_either
          Dry::Monads::Left(@exception)
        end

        def ==(other)
          other.is_a?(Failure) && @exception == other.exception
        end

        def to_s
          "Try::Failure(#{exception.class}: #{exception.message})"
        end
        alias inspect to_s
      end

      module Mixin
        Try = Try

        def Try(*exceptions, &f)
          catchable = exceptions.any? ? exceptions.flatten : [StandardError]
          Try.lift(catchable, f)
        end
      end
    end
  end
end
