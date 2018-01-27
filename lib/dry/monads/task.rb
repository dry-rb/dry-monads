require 'concurrent/promise'

require 'dry/monads/curry'

module Dry
  module Monads
    # The Task monad represents an async computation. The implementation
    # is a rather thin wrapper of Concurrent::Promise from the concurrent-ruby.
    # The API supports setting a custom executor from concurrent-ruby.
    #
    # @api public
    class Task
      # @api private
      class Promise < Concurrent::Promise
        public :on_fulfill, :on_reject
      end
      private_constant :Promise

      class << self
        # Creates a Task from a block
        #
        # @param block [Proc]
        # @return [Task]
        def new(promise = nil, &block)
          if promise
            super(promise)
          else
            super(Promise.execute(&block))
          end
        end

        # Creates a Task with the given executor
        #
        # @example providing an executor instance, using Ruby 2.5+ syntax
        #   IO = Concurrent::ThreadPoolExecutor.new
        #   Task[IO] { do_http_request }
        #
        # @example using a predefined executor
        #    Task[:fast] { do_quick_task }
        #
        # @param executor [Concurrent::AbstractExecutorService,Symbol] Either an executor instance
        #                                                              or a name of predefined global
        #                                                              from concurrent-ruby
        # @return [Task]
        def [](executor, &block)
          new(Promise.execute(executor: executor, &block))
        end

        # Returns a complete task from the given value
        #
        # @param value [Object]
        # @param block [Proc]
        # @return [Task]
        def pure(value = Undefined, &block)
          if value.equal?(Undefined)
            new(Promise.fulfill(block))
          else
            new(Promise.fulfill(value))
          end
        end
      end

      # @api private
      attr_reader :promise
      protected :promise

      # @api private
      def initialize(promise)
        @promise = promise
      end

      # Retrieves the value of the computation.
      # Blocks current thread if the underlying promise
      # hasn't been complete yet.
      # Throws an error if the computation failed.
      #
      # @return [Object]
      # @api public
      def value!
        if promise.wait.fulfilled?
          promise.value
        else
          raise promise.reason
        end
      end

      # Lifts a block over the Task monad.
      #
      # @param block [Proc]
      # @return [Task]
      # @api public
      def fmap(&block)
        self.class.new(promise.then(&block))
      end

      # Composes two tasks to run one after another.
      # A more common name is `then` exists as an alias.
      #
      # @param block [Proc] A block that yields the result of the current task
      #                     and returns another task
      # @return [Task]
      def bind(&block)
        self.class.new(promise.flat_map { |value| block.(value).promise })
      end
      alias_method :then, :bind

      # Converts to Result. Blocks the current thread if required.
      #
      # @return [Result]
      def to_result
        if promise.wait.fulfilled?
          Result::Success.new(promise.value)
        else
          Result::Failure.new(promise.reason)
        end
      end

      # Converts to Maybe. Blocks the current thread if required.
      #
      # @return [Maybe]
      def to_maybe
        Maybe.coerce(promise.wait.value)
      end

      # @return [String]
      def to_s
        state = case promise.state
                when :fulfilled
                  "state=complete value=#{ value!.inspect }"
                when :rejected
                  "state=rejected error=#{ promise.reason.inspect }"
                else
                  'state=pending'
                end

        "Task(#{ state })"
      end
      alias_method :inspect, :to_s

      # Tranforms the error if the computation wasn't successful.
      #
      # @param block [Proc]
      # @return [Task]
      def or_fmap(&block)
        self.class.new(promise.rescue(&block))
      end

      # Rescues the error with a block that returns another task.
      #
      # @param block [Proc]
      # @return [Object]
      def or(&block)
        child = Promise.new(
          parent: promise,
          executor: Concurrent::ImmediateExecutor.new
        )

        promise.on_error do |v|
          begin
            inner = block.(v).promise
            inner.execute
            inner.on_success { |r| child.on_fulfill(r) }
            inner.on_error { |e| child.on_reject(e) }
          rescue => e
            child.on_reject(e)
          end
        end
        promise.on_success  { |v| child.on_fulfill(v) }

        self.class.new(child)
      end

      # Extracts the resulting value if the computation was successful
      # otherwise yields the block and returns its result.
      #
      # @param block [Proc]
      # @return [Object]
      def value_or(&block)
        promise.rescue(&block).wait.value
      end

      # Blocks the current thread until the task is complete.
      #
      # @return [Task]
      def wait(timeout = nil)
        promise.wait(timeout)
        self
      end

      # Compares two tasks. Note, it works
      # good enough only for complete tasks.
      #
      # @return [Boolean]
      def ==(other)
        return true if equal?(other)
        return false unless self.class == other.class
        compare_promises(promise, other.promise)
      end

      # Whether the computation is complete.
      #
      # @return [Boolean]
      def complete?
        promise.complete?
      end

      # @return [Class]
      def monad
        Task
      end

      # Applies the stored value to the given argument.
      #
      # @example
      #   Task.
      #     pure { |x, y| x ** y }.
      #     apply(Task { 2 }).
      #     apply(Task { 3 }).
      #     to_maybe # => Some(8)
      #
      # @param arg [Task]
      # @return [Task]
      def apply(arg)
        bind { |f| arg.fmap { |v| curry(f).(v) } }
      end

      private

      # @api private
      def curry(value)
        if defined?(@curried)
          if @curried[0].equal?(value)
            @curried[1]
          else
            Curry.(value)
          end
        else
          @curried = [value, Curry.(value)]
          @curried[1]
        end
      end

      # @api private
      def compare_promises(x, y)
        x.equal?(y) ||
          x.fulfilled? && y.fulfilled? && x.value == y.value ||
          x.rejected? && y.rejected? && x.reason == y.reason
      end

      # Task constructors.
      #
      # @api public
      module Mixin
        Task = Task # @private

        # Created a mixin with the given executor injected.
        #
        # @param executor [Concurrent::AbstractExecutorService,Symbol]
        # @return [Module]
        def self.[](executor)
          Module.new do
            include Mixin

            # Created a new Task with an injected executor.
            #
            # @param block [Proc]
            # @return [Task]
            define_method(:Task) do |&block|
              Task[executor, &block]
            end
          end
        end

        # Builds a new Task instance.
        #
        # @param block [Proc]
        # @return Task
        def Task(&block)
          Task.new(&block)
        end
      end
    end
  end
end
