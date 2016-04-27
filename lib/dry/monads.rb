require 'dry/monads/either'
require 'dry/monads/maybe'

module Dry
  module Monads
    def self.Maybe(value)
      Maybe.lift(value)
    end

    def self.Some(value)
      Maybe::Some.new(value)
    end

    def self.None
      Maybe::Some::None.instance
    end

    def self.Right(value)
      Either::Right.new(value)
    end

    def self.Left(value)
      Either::Left.new(value)
    end
  end
end
