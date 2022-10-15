# frozen_string_literal: true

module Dry
  module Monads
    # An implementation of do-notation.
    #
    # @see Do.for
    module Do
      extend Mixin

      VISIBILITY_WORD = {
        public: "",
        private: "private ",
        protected: "protected "
      }.freeze

      # @api private
      class Halt < StandardError
        # @api private
        attr_reader :result

        def initialize(result)
          super()

          @result = result
        end
      end

      # @api private
      class MethodTracker < ::Module
        # @api private
        def initialize(tracked_methods, base, wrapper)
          module_eval do
            private

            define_method(:method_added) do |method|
              super(method)

              if tracked_methods.include?(method)
                visibility = Do.method_visibility(base, method)
                Do.wrap_method(wrapper, method, visibility)
              end
            end
          end
        end
      end

      class << self
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
        def for(*methods)
          ::Module.new do
            singleton_class.define_method(:included) do |base|
              mod = ::Module.new
              base.prepend(mod)
              base.extend(MethodTracker.new(methods, base, mod))
            end
          end
        end

        # @api private
        def included(base)
          super

          # Actually mixes in Do::All
          require "dry/monads/do/all"
          base.include All
        end

        # @api private
        def wrap_method(target, method, visibility)
          target.module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            #{VISIBILITY_WORD[visibility]} def #{method}(...) # private def create_acccount(...)
              if block_given?                                 #   if block_given?
                super                                         #     super
              else                                            #   else
                Do.() { super { |*ms| Do.bind(ms) } }         #     Do.() { super { |*ms| Do.bind(ms) } }
              end                                             #   end
            end                                               # end
          RUBY
        end

        # @api private
        def method_visibility(mod, method)
          if mod.public_method_defined?(method)
            :public
          elsif mod.private_method_defined?(method)
            :private
          else
            :protected
          end
        end

        # @api private
        def coerce_to_monad(monads)
          return monads if monads.size != 1

          first = monads[0]

          case first
          when ::Array
            [List.coerce(first).traverse]
          when List
            [first.traverse]
          else
            monads
          end
        end

        # @api private
        def halt(result)
          raise Halt.new(result), "", []
        end
      end
    end
  end
end
