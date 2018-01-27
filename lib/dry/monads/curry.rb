module Dry
  module Monads
    module Curry
      def self.call(value)
        func = value.is_a?(Proc) ? value : value.method(:call)
        seq_args = func.parameters.count { |type, _| type == :req }
        seq_args += 1 if func.parameters.any? { |type, _| type == :keyreq }

        if seq_args > 1
          func.curry
        else
          func
        end
      end
    end
  end
end
