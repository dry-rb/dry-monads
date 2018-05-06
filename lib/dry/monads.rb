module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api public
  module Monads
    def self.included(base)
      if const_defined?(:CONSTRUCTORS)
        base.include(*CONSTRUCTORS)
      else
        raise "Load all monads first with require 'dry/monads/all'"
      end
    end
  end
end
