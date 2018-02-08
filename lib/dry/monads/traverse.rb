require 'dry/monads/validated'

module Dry
  module Monads
    to_list = List::Validated.method(:pure)

    ID = -> x { x }

    Traverse = {
      Validated => -> el { el.alt_map(to_list) }
    }

    Traverse.default = ID
    Traverse.freeze
  end
end
