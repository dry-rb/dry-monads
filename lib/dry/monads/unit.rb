# frozen_string_literal: true

module Dry
  module Monads
    # Unit is a special object you can use whenever your computations don't
    # return any payload. Previously, if your function ran a side-effect
    # and returned no meaningful value, you had to return things like
    # Success(nil), Success([]), Success({}), Maybe(""), Success(true) and
    # so forth.
    #
    # You should use Unit if you wish to return an empty monad.
    #
    # @example with Result
    #   Success(Unit)
    #   Failure(Unit)
    #
    # @example with Maybe
    #   Maybe(Unit)
    #   => Some(Unit)
    #
    Unit = ::Object.new.tap do |unit|
      def unit.to_s
        "Unit"
      end

      def unit.inspect
        "Unit"
      end

      def unit.deconstruct
        EMPTY_ARRAY
      end

      unit.freeze
    end
  end
end
