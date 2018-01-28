require 'concurrent/promise'

require 'dry/monads/task'

module Dry
  module Monads
    # Lazy is a twin of Task which is always executed on the current thread.
    # The underlying mechanism provided by concurrent-ruby ensures the given
    # computation is evaluated not more than once (compare with the built-in
    # lazy assignement ||= which does not guarantee this).
    class Lazy < Task
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

      # @return [String]
      def to_s
        state = case promise.state
                when :fulfilled
                  value!.inspect
                when :rejected
                  "!#{ promise.reason.inspect }"
                else
                  '?'
                end

        "Lazy(#{ state })"
      end
      alias_method :inspect, :to_s

      # Lazy constructors
      #
      module Mixin
        # @see Dry::Monads::Lazy
        Lazy = Lazy

        # Lazy computation contructor
        # @return [Lazy]
        def Lazy(&block)
          Lazy.new(&block)
        end
      end
    end
  end
end
