module Dry::Monads
  class Result
    # @see Monads#Result
    # @private
    class Fixed < Module
      def self.[](error, **options)
        new(error, **options)
      end

      def initialize(error, **options)
        @mod = Module.new do
          define_method(:Failure) do |value|
            if error === value
              Failure.new(value)
            else
              raise InvalidFailureTypeError.new(value)
            end
          end

          def Success(value)
            Success.new(value)
          end
        end
      end

      # @api private
      def included(base)
        super

        base.include(@mod)
      end
    end
  end
end
