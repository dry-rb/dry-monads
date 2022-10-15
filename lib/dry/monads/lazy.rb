# frozen_string_literal: true

require "concurrent/promise"

module Dry
  module Monads
    # Lazy is a twin of Task which is always executed on the current thread.
    # The underlying mechanism provided by concurrent-ruby ensures the given
    # computation is evaluated not more than once (compare with the built-in
    # lazy assignement ||= which does not guarantee this).
    class Lazy < Task
      extend ::Dry::Core::Deprecations[:"dry-monads"]

      class << self
        # @private
        def new(promise = nil, &block)
          if promise
            super(promise)
          else
            super(Concurrent::Promise.new(executor: :immediate, &block))
          end
        end

        private :[]
      end

      # Forces the compution and returns its value.
      #
      # @return [Object]
      def value!
        @promise.execute.value!
      end
      alias_method :force!, :value!

      # Forces the computation. Note that if the computation
      # thrown an error it won't be re-raised as opposed to value!/force!.
      #
      # @return [Lazy]
      def force
        @promise.execute
        self
      end

      # @return [Boolean]
      def evaluated?
        @promise.complete?
      end
      deprecate :complete?, :evaluated?

      undef_method :wait

      # @return [String]
      def to_s
        state = case promise.state
                when :fulfilled
                  value!.inspect
                when :rejected
                  "!#{promise.reason.inspect}"
                else
                  "?"
                end

        "Lazy(#{state})"
      end
      alias_method :inspect, :to_s

      # Lazy constructors
      #
      module Mixin
        # @see Dry::Monads::Lazy
        Lazy = Lazy

        # @see Dry::Monads::Unit
        Unit = Unit

        # Lazy constructors
        module Constructors
          # Lazy computation contructor
          #
          # @param block [Proc]
          # @return [Lazy]
          def Lazy(&block)
            Lazy.new(&block)
          end
        end

        include Constructors
      end
    end

    require "dry/monads/registry"
    register_mixin(:lazy, Lazy::Mixin)
  end
end
