# frozen_string_literal: true

module Dry
  module Monads
    module ConversionStubs
      def self.[](*method_names)
        Module.new do
          method_names.each do |name|
            define_method(name) do |*|
              Methods.public_send(name)
            end
          end
        end
      end

      module Methods
        module_function

        def to_maybe
          raise "Load Maybe first with require 'dry/monads/maybe'"
        end

        def to_result
          raise "Load Result first with require 'dry/monads/result'"
        end

        def to_validated
          raise "Load Validated first with require 'dry/monads/validated'"
        end
      end
    end
  end
end
