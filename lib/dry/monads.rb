require 'dry/core/constants'
require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/result'
require 'dry/monads/result/fixed'

module Dry
  # @api public
  module Monads
    extend self

    Undefined = Dry::Core::Constants::Undefined

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

    # Creates a module that has two methods: `Success` and `Failure`.
    # `Success` is identical to {Monads#Success} and Failure
    # rejects values that don't conform the value of the `error`
    # parameter. This is essentially a Result type with the `Failure` part
    # fixed.
    #
    # @example using dry-types
    #   module Types
    #     include Dry::Types.module
    #   end
    #
    #   class Operation
    #     # :user_not_found and :account_not_found are the only
    #     # values allowed as failure results
    #     Error =
    #       Types.Value(:user_not_found) |
    #       Types.Value(:account_not_found)
    #
    #     def find_account(id)
    #       account = acount_repo.find(id)
    #
    #       account ? Success(account) : Failure(:account_not_found)
    #     end
    #
    #     def find_user(id)
    #       # ...
    #     end
    #   end
    #
    # @param error [#===] the type of allowed failures
    # @return [Module]
    def Result(error, **options)
      Result::Fixed[error, **options]
    end
  end
end
