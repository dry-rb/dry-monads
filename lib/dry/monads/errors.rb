module Dry
  module Monads
    class UnwrapError < StandardError
      def initialize(ctx)
        super("value! was called on #{ ctx.inspect }")
      end
    end

    class InvalidFailureTypeError < StandardError
      def initialize(failure)
        super("Cannot create Failure from #{ failure.inspect }, it doesn't meet constraints")
      end
    end
  end
end
