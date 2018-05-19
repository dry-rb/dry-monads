# frozen_string_literal: true

module Dry
  module Monads
    Unit = Object.new.tap do |unit|
      def unit.to_s
        'Unit'
      end

      def unit.inspect
        'Unit'
      end
    end
  end
end
