# frozen_string_literal: true

module Dry
  module Monads
    module Do
      # Do notation as a mixin.
      # You can use it in any place in your code, see examples.
      #
      # @example class-level mixin
      #
      #   class CreateUser
      #     extend Dry::Monads::Do::Mixin
      #     extend Dry::Monads[:result]
      #
      #     def self.run(params)
      #       self.call do
      #         values = bind Validator.validate(params)
      #         user = bind UserRepository.create(values)
      #
      #         Success(user)
      #       end
      #     end
      #   end
      #
      # @example using methods defined on Do
      #
      #   create_user = proc do |params|
      #     Do.() do
      #       values = bind validate(params)
      #       user = bind user_repo.create(values)
      #
      #       Success(user)
      #     end
      #   end
      #
      # @api public
      module Mixin
        # @api public
        def call
          yield
        rescue Halt => e
          e.result
        end

        # @api public
        def bind(monads)
          monads = Do.coerce_to_monad(Array(monads))
          unwrapped = monads.map do |result|
            monad = result.to_monad
            monad.or { Do.halt(monad) }.value!
          end
          monads.size == 1 ? unwrapped[0] : unwrapped
        end
      end
    end
  end
end
