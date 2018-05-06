require 'dry/monads'
require 'dry/monads/do'
require 'dry/monads/lazy'
require 'dry/monads/list'
require 'dry/monads/maybe'
require 'dry/monads/result'
require 'dry/monads/result/fixed'
require 'dry/monads/task'
require 'dry/monads/try'
require 'dry/monads/validated'

module Dry
  module Monads
    # List of monad constructors
    CONSTRUCTORS = [
      Lazy::Mixin::Constructors,
      Maybe::Mixin::Constructors,
      Result::Mixin::Constructors,
      Task::Mixin::Constructors,
      Try::Mixin::Constructors,
      Validated::Mixin::Constructors,
    ].freeze

    extend(*CONSTRUCTORS)
  end
end
