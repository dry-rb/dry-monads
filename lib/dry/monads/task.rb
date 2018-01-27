require 'concurrent/promise'

module Dry
  module Monads
    class Task
      def self.new(promise = nil, &block)
        if block
          super(Concurrent::Promise.execute(&block))
        else
          super(promise)
        end
      end

      attr_reader :promise
      protected :promise

      def initialize(promise)
        @promise = promise
      end

      def value!
        promise.wait

        if promise.fulfilled?
          promise.value
        else
          raise UnwrapError.new(self)
        end
      end

      def fmap(&block)
        self.class.new(promise.then(&block))
      end

      def bind(&block)
        self.class.new(promise.flat_map { |value| block.(value).promise })
      end

      def to_result
        promise.wait

        if promise.fulfilled?
          Result::Success.new(promise.value)
        else
          Result::Failure.new(promise.reason)
        end
      end

      def to_maybe
        Maybe.coerce(promise.wait.value)
      end

      def to_s
        state, internal = case promise.state
                          when :fulfilled
                            ['resolved', " value=#{ value!.inspect }"]
                          when :rejected
                            ['rejected', " error=#{ promise.reason.inspect }"]
                          else
                            'pending'
                          end

        "Task(state=#{ state }#{ internal })"
      end
      alias_method :inspect, :to_s

      def or_fmap(&block)
        self.class.new(promise.rescue(&block))
      end

      def or(&block)
        child = Concurrent::Promise.new(executor: Concurrent::ImmediateExecutor.new)
        promise.rescue(&child.method(:set))

        self.class.new(child).bind(&block)
      end

      def value_or(&block)
        promise.rescue(&block).wait.value
      end

      def wait(timeout = nil)
        promise.wait(timeout)
        self
      end

      def ==(other)
        return true if equal?(other)
        return false unless self.class == other.class
        compare_promises(promise, other.promise) { |x, y| x == y }
      end

      def eql?(other)
        return true if equal?(other)
        return false unless self.class == other.class
        compare_promises(promise, other.promise) { |x, y| x.eql?(y) }
      end

      def complete?
        promise.complete?
      end

      private

      def compare_promises(x, y)
        x.equal?(y) ||
          x.fulfilled? && y.fulfilled? && yield(x.value, y.value) ||
          x.rejected? && y.rejected? && yield(x.reason, y.reason)
      end
    end
  end
end
