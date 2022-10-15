# frozen_string_literal: true

require "dry/monads"

module Dry
  module Monads
    known_monads.each { load_monad(_1) }
    extend(*constructors)
  end
end
