require 'dry/monads/either'
require 'dry/monads/maybe'
require 'dry/monads/try'

module Dry
  module Monads
    extend self

    def Maybe(value)
      Maybe.lift(value)
    end

    def Some(value)
      Maybe::Some.new(value)
    end

    def None
      Maybe::Some::None.instance
    end

    def Right(value)
      Either::Right.new(value)
    end

    def Left(value)
      Either::Left.new(value)
    end
  end
end
