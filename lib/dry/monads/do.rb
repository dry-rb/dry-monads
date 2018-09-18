require 'dry/monads/list'

module Dry
  module Monads
    # An implementation of do-notation.
    #
    # @see Do.for
    module Do
      # @private
      class Halt < StandardError
        # @private
        attr_reader :result

        def initialize(result)
          super()

          @result = result
        end
      end

      # Generates a module that passes a block to methods
      # that either unwraps a single-valued monadic value or halts
      # the execution.
      #
      # @example A complete example
      #
      #   class CreateUser
      #     include Dry::Monads::Result::Mixin
      #     include Dry::Monads::Try::Mixin
      #     include Dry::Monads::Do.for(:call)
      #
      #     attr_reader :user_repo
      #
      #     def initialize(:user_repo)
      #       @user_repo = user_repo
      #     end
      #
      #     def call(params)
      #       json = yield parse_json(params)
      #       hash = yield validate(json)
      #
      #       user_repo.transaction do
      #         user = yield create_user(hash[:user])
      #         yield create_profile(user, hash[:profile])
      #       end
      #
      #       Success(user)
      #     end
      #
      #     private
      #
      #     def parse_json(params)
      #       Try(JSON::ParserError) {
      #         JSON.parse(params)
      #       }.to_result
      #     end
      #
      #     def validate(json)
      #       UserSchema.(json).to_monad
      #     end
      #
      #     def create_user(user_data)
      #       Try(Sequel::Error) {
      #         user_repo.create(user_data)
      #       }.to_result
      #     end
      #
      #     def create_profile(user, profile_data)
      #       Try(Sequel::Error) {
      #         user_repo.create_profile(user, profile_data)
      #       }.to_result
      #     end
      #   end
      #
      # @param [Array<Symbol>] methods
      # @return [Module]
      def self.for(*methods)
        mod = Module.new do
          methods.each { |method_name| Do.wrap_method(self, method_name) }
        end

        Module.new do
          singleton_class.send(:define_method, :included) do |base|
            base.prepend(mod)
          end
        end
      end

      # @api private
      def self.included(base)
        super

        # Actually mixes in Do::All
        require 'dry/monads/do/all'
        base.include All
      end

      protected

      # @private
      def self.halt(result)
        raise Halt.new(result)
      end

      # @private
      def self.coerce_to_monad(monads)
        return monads if monads.size != 1

        first = monads[0]

        case first
        when Array
          [List.coerce(first).traverse]
        when List
          [first.traverse]
        else
          monads
        end
      end

      # @private
      def self.wrap_method(target, method_name)
        target.module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{ method_name }(*)
            if block_given?
              super
            else
              super do |*monads|
                monads = Do.coerce_to_monad(monads)
                unwrapped = monads.map { |result|
                  monad = result.to_monad
                  monad.or { Do.halt(monad) }.value!
                }
                monads.size == 1 ? unwrapped[0] : unwrapped
              end
            end
          rescue Halt => e
            e.result
          end
        RUBY
      end
    end
  end
end
