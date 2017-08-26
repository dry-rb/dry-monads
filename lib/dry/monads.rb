require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/result'
require 'dry/monads/result/fixed'

module Dry
  # @api public
  module Monads
    extend self

    # Stores the given value in one of the subtypes of {Maybe} monad.
    # It is essentially a wrapper for {Maybe.lift}.
    #
    # @param value [Object] the value to be stored in the monad
    # @return [Maybe::Some, Maybe::None]
    def Maybe(value)
      Maybe.lift(value)
    end

    # @param value [Object] the value to be stored in the monad
    # @return [Maybe::Some]
    def Some(value)
      Maybe::Some.new(value)
    end

    # @return [Maybe::None]
    def None
      Maybe::Some::None.instance
    end

    # @note This method is provided for backwards compatibility.
    # @param value [Object] the value to be stored in the monad
    # @return [Result::Success]
    def Right(value)
      Result::Success.new(value)
    end

    # @note This method is provided for backwards compatibility.
    # @param value [Object] the value to be stored in the monad
    # @return [Result::Failure]
    def Left(value)
      Result::Failure.new(value)
    end

    # @param value [Object] the value to be stored in the monad
    # @return [Result::Success]
    def Success(value)
      Result::Success.new(value)
    end

    # @param value [Object] the value to be stored in the monad
    # @return [Result::Failure]
    def Failure(value)
      Result::Failure.new(value)
    end

    def Result(error, **options)
      Result::Fixed[error, **options]
    end
  end
end
