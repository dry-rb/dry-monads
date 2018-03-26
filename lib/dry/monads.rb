require 'dry/monads/undefined'
require 'dry/monads/maybe'
require 'dry/monads/try'
require 'dry/monads/list'
require 'dry/monads/task'
require 'dry/monads/lazy'
require 'dry/monads/result'
require 'dry/monads/result/fixed'
require 'dry/monads/do'
require 'dry/monads/validated'

module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api public
  module Monads
    # List of monad constructors
    CONSTRUCTORS = [
      Maybe::Mixin::Constructors,
      Validated::Mixin::Constructors,
      Try::Mixin::Constructors,
      Task::Mixin::Constructors,
      Lazy::Mixin::Constructors
    ].freeze

    # @see Maybe::Some
    Some = Maybe::Some
    # @see Maybe::None
    None = Maybe::None
    # @see Validated::Valid
    Valid = Validated::Valid
    # @see Validated::Invalid
    Invalid = Validated::Invalid

    extend(*CONSTRUCTORS)

    # @private
    def self.included(base)
      super

      base.include(*CONSTRUCTORS)
    end
  end
end
