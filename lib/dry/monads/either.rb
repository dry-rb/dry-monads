require 'dry/core/deprecations'

Dry::Core::Deprecations.warn('Either monad was renamed to Result', tag: :'dry-monads')

require 'dry/monads/result'

module Dry
  module Monads
    Either = Result
    deprecate_constant :Either

    class Result
      extend Dry::Core::Deprecations[:'dry-monads']

      deprecate :to_either, :to_result

      Right = Success
      Left = Failure

      deprecate_constant :Right
      deprecate_constant :Left

      module Mixin
        module Constructors
          extend Dry::Core::Deprecations[:'dry-monads']

          Right = Success
          Left = Failure
          deprecate_constant :Right
          deprecate_constant :Left

          deprecate :Right, :Success
          deprecate :Left, :Failure
        end
      end

      class Success
        deprecate :left?, :failure?
        deprecate :right?, :success?
      end

      class Failure
        deprecate :left?, :failure?
        deprecate :right?, :success?

        deprecate :left, :failure
      end
    end

    class Try
      class Value
        extend Dry::Core::Deprecations[:'dry-monads']

        deprecate :to_either, :to_result
      end

      class Error
        extend Dry::Core::Deprecations[:'dry-monads']

        deprecate :to_either, :to_result
      end
    end
  end
end
