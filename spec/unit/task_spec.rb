require 'thread'

RSpec.describe(Dry::Monads::Task) do
  result = Dry::Monads::Result
  success = result::Success.method(:new)

  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)

  task = described_class

  def task(&block)
    described_class.new(&block)
  end

  def deferred(&block)
    -> do
      expect(Thread.current).not_to be(Thread.main)
      block.call
    end
  end

  subject do
    task(&deferred { 1 })
  end

  describe '.new' do
    it 'delays the execution' do
      expect(subject.value!).to be 1
    end
  end

  describe '#fmap' do
    it 'chains transformations' do
      chain = subject.fmap { |v| v * 2 }

      expect(chain.value!).to be 2
    end

    it 'runs a block only on success' do
      called = false
      t = task { 1 / 0 }.fmap { called = true }
      t.to_result

      expect(called).to be(false)
    end
  end

  describe '#bind' do
    it 'combines tasks' do
      chain = subject.bind { |v| task { v * 2 } }

      expect(chain.value!).to be 2
    end
  end

  describe '#then' do
    it 'is an alias of #bind' do
      expect(subject.method(:then)).to eql(subject.method(:bind))
    end
  end

  describe '#to_result' do
    it 'transforms a successful execution to Result' do
      expect(subject.to_result).to eql(success[1])
    end

    it 'transforms an unsuccessful result to a Failure' do
      error = task { 1 / 0 }.to_result
      expect(error).to be_a_failure
      expect(error.failure).to be_a(ZeroDivisionError)
    end
  end

  describe '#to_maybe' do
    it 'transforms a successful execution to Some' do
      expect(subject.to_maybe).to eql(some[1])
    end

    it 'transforms an unsuccessful result to None' do
      error = task { 1 / 0 }.to_maybe
      expect(error).to be_none
    end
  end

  describe '#value!' do
    it 'unwraps the value' do
      expect(subject.value!).to be 1
    end

    it 'raises an error on unsuccessful computation' do
      expect { task { 1 / 0 }.value! }.to raise_error(ZeroDivisionError)
    end
  end

  describe '#inspect' do
    it 'inspects pending' do
      t = task { sleep 0.01 }
      expect(t.inspect).to eql("Task(?)")
    end

    it 'inspects complete' do
      t = task { :something }.tap(&:value!)
      expect(t.inspect).to eql("Task(value=:something)")
    end

    it 'inspects failed' do
      1 / 0 rescue err = $!
      t = task { raise err }.tap(&:to_result)
      expect(t.inspect).to eql("Task(error=#{ err.inspect })")
    end
  end

  describe '#to_s' do
    it 'is an alias for inspect' do
      expect(subject.method(:to_s)).to eql(subject.method(:inspect))
    end
  end

  describe '#or' do
    it 'runs a block on failure' do
      m = task { 1 / 0 }.or { task { :success } }
      expect(m.wait).to be == task { :success }.wait
    end

    it 'ignores blocks on success' do
      m = subject.or { task { :success } }
      expect(m.wait).to be == task { 1 }.wait
    end
  end

  describe '#or_fmap' do
    it 'runs a block on failure' do
      m = task { 1 / 0 }.or_fmap { :success }.to_result
      expect(m).to eql(success[:success])
    end
  end

  describe '#value_or' do
    specify 'if success unwraps the value' do
      expect(subject.value_or { 2 }).to be(1)
    end

    specify 'if failure calls the given block' do
      expect(task { 1 / 0 }.value_or { 2 }).to be(2)
    end
  end

  describe '#complete?' do
    it 'checks whether the task is complete' do
      expect(task { sleep 0.01 }.wait).to be_complete
      expect(task { sleep 0.01 }).not_to be_complete
    end
  end

  describe '#wait' do
    it 'waits for resolution' do
      expect(task { sleep 0.01 }.wait).to be_complete
      expect(task { sleep 0.01 }).not_to be_complete
    end

    it 'accepts a timeout' do
      expect(task { sleep 10 }.wait(0.01)).not_to be_complete
    end
  end

  describe '.[]' do
    let(:immediate) { Concurrent::ImmediateExecutor.new }

    it 'allows to inject an underlying executor' do
      expect(task[immediate, &-> { Thread.current }].to_result).to eql(success[Thread.main])
    end

    it 'supports global pools' do
      expect(task[:immediate, &-> { Thread.current }].to_result).to eql(success[Thread.main])
      expect(task[:io, &-> { Thread.current }].to_result).not_to eql(success[Thread.main])
      expect(task[:fast, &-> { Thread.current }].to_result).not_to eql(success[Thread.main])
    end
  end

  describe '.pure' do
    it 'creates a resolved task' do
      expect(task.pure(1)).to be == subject.wait
    end

    it 'accepts a block too' do
      one = -> { 1 }
      expect(task.pure(&one)).to be == task { one }.wait
    end
  end

  describe '#apply' do
    let(:two) { task { 2 } }
    let(:three) { task { 3 } }

    it 'applies arguments to the underlying callable' do
      lifted = task.pure(-> x { x * 2 })
      expect(lifted.apply(two).to_result).to eql(success[4])
    end

    it 'curries the callable' do
      lifted = task.pure(-> x, y { x * y * 2 })
      expect(lifted.apply(two).apply(three).to_result).to eql(success[12])
    end

    it 'can be used via pure with block' do
      lifted = task.pure { |x, y| x * y * 2 }
      expect(lifted.apply(two).apply(three).to_result).to eql(success[12])
    end
  end
end
