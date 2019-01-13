require 'dry/monads'
require 'dry/monads/registry'

module Dry
  module Monads
    known_monads.each { |m| load_monad(m) }
    @registry.freeze
    extend(*monad_constructors)
  end
end
