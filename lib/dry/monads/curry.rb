# frozen_string_literal: true

module Dry
  module Monads
    # @private
    module Curry
      # @private
      def self.call(value)
        func = value.is_a?(Proc) ? value : value.method(:call)
        seq_args = func.parameters.count { |type, _| type.eql?(:req) || type.eql?(:opt) }
        seq_args += 1 if func.parameters.any? { |type, _| type.eql?(:keyreq) }

        if seq_args > 1
          func.curry
        else
          func
        end
      end
    end
  end
end
