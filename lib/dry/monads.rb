require 'dry/core/constants'
require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/task'
require 'dry/monads/lazy'
require 'dry/monads/result'
require 'dry/monads/result/fixed'
require 'dry/monads/do'

module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api public
  module Monads
    # @private
    Undefined = Dry::Core::Constants::Undefined

    # @private
    CONSTRUCTORS = [
      Maybe::Mixin::Constructors,
      Result::Mixin::Constructors
    ].freeze

    # @see Maybe::Some
    Some = Maybe::Some
    # @see Maybe::None
    None = Maybe::None
    # @see Result::Success
    Success = Result::Success
    # @see Result::Failure
    Failure = Result::Failure

    extend(*CONSTRUCTORS)

    # @private
    def self.included(base)
      super

      base.include(*CONSTRUCTORS)
    end

    # Creates a module that has two methods: `Success` and `Failure`.
    # `Success` is identical to {Result::Mixin::Constructors#Success} and Failure
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
    def self.Result(error, **options)
      Result::Fixed[error, **options]
    end
  end
end
