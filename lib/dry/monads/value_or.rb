module Dry
  module Monads
    module ValueOrPositive
      # Returns value. It exists to keep the interface identical to that of ValueOrNegative.
      #
      # @return [Object]
      def value_or(_val = nil)
        value
      end
    end

    module ValueOrNegative
      # Returns the passed value
      #
      # @returns [Object]
      def value_or(val = nil)
        if block_given?
          yield
        else
          val
        end
      end
    end
  end
end
