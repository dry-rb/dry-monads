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
    CONSTRUCTORS = [].freeze

    extend(*CONSTRUCTORS)

    # @private
    def self.included(base)
      super

      # TODO: Fix once CONSTRUCTORS is empty
      base.include(*CONSTRUCTORS)
    end
  end
end
