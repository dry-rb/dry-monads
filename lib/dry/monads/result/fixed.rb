# frozen_string_literal: true

require "dry/monads/constants"

module Dry::Monads
  class Result
    # @see Monads#Result
    # @private
    class Fixed < ::Module
      def self.[](error, **options)
        new(error, **options)
      end

      def initialize(error, **_options)
        @mod = Module.new do
          define_method(:Failure) do |value|
            if error === value
              Failure.new(value, RightBiased::Left.trace_caller)
            else
              raise InvalidFailureTypeError, value
            end
          end

          def Success(value = Undefined, &block)
            v = Undefined.default(value, block || Unit)
            Success.new(v)
          end
        end
      end

      private

      def included(base)
        super

        base.include(@mod)
      end
    end
  end
end
