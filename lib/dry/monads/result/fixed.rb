module Dry::Monads
  class Result
    class Fixed < Module
      def self.[](error, **options)
        new(error, **options)
      end

      def initialize(error, **options)
        @mod = Module.new do
          define_method(:Failure) do |value|
            Failure.new(error[value])
          end

          def Success(value)
            Success.new(value)
          end
        end
      end

      def included(base)
        super

        base.include(@mod)
      end
    end
  end
end
