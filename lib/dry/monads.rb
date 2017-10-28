require 'dry/monads/either'
require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/result'

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

    # @param value [Object] the value to be stored in the monad
    # @return [Either::Right]
    def Right(value)
      Either::Right.new(value)
    end

    # @param value [Object] the value to be stored in the monad
    # @return [Either::Left]
    def Left(value)
      Either::Left.new(value)
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
  end
end
