module Dry
  module Monads
    class UnwrapError < StandardError
      def initialize(left)
        super("value! was called on #{ left.inspect }")
      end
    end
  end
end
