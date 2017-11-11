require 'dry/core/constants'
require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/result'
require 'dry/monads/result/fixed'

module Dry
  # @api public
  module Monads
    Undefined = Dry::Core::Constants::Undefined

    CONSTRUCTORS = [
      Maybe::Mixin::Constructors,
      Result::Mixin::Constructors
    ].freeze

    extend(*CONSTRUCTORS)

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
