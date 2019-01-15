require 'dry/core/extensions'

module Dry
  module Monads
    class Maybe
      extend Dry::Core::Extensions

      register_extension(:string_serialization) do
        class Some
          # Serializes inner value to a string and returns the result.
          #
          # @return [String] the result of calling `#to_str` in the inner value
          # @raise [NoMethodError] when inner value does not respond to `#to_str`
          def to_str!
            fmap(&:to_str).value!
          end
        end

        class None
          # Returns empty string.
          #
          # @return [String]
          def to_str!
            ''
          end
        end
      end
    end
  end
end