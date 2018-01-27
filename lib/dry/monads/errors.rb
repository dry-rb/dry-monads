module Dry
  module Monads
    # An unsuccessful result of extracting a value from a monad.
    class UnwrapError < StandardError
      def initialize(ctx)
        super("value! was called on #{ ctx.inspect }")
      end
    end

    # An error thrown on returning a Failure of unknown type.
    class InvalidFailureTypeError < StandardError
      def initialize(failure)
        super("Cannot create Failure from #{ failure.inspect }, it doesn't meet the constraints")
      end
    end
  end
end
