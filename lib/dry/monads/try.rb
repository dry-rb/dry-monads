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
        def initialize(exceptions, value)
          @catchable = exceptions
          @value = value
        end

        def bind(f)
          f.call(@value)
        rescue => e
          Failure.new(e)
        end
        alias >> bind

        def fmap(&_f)
          Try.lift @catchable, -> { yield(@value) }
        end

        def to_maybe
          Dry::Monads::Maybe(@value)
        end

        def to_either
          Dry::Monads::Right(@value)
        end
      end

      class Failure < Try
        def initialize(exception)
          @exception = exception
        end

        def bind(_f)
          self
        end
        alias >> bind

        def fmap(&_f)
          self
        end

        def to_maybe
          Dry::Monads::None()
        end

        def to_either
          Dry::Monads::Left(@exception)
        end
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
