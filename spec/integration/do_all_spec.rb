require 'dry/monads/result'
require 'dry/monads/do/all'

RSpec.describe(Dry::Monads::Do::All) do
  let(:mixin) { described_class }
  result_mixin = Dry::Monads::Result::Mixin
  include result_mixin

  context 'include first' do
    let(:adder) do
      spec = self
      klass = Class.new {
        include spec.mixin

        def sum(a, b)
          c = yield(a) + yield(b)
          Success(c)
        end
      }.tap { |c| c.include(result_mixin) }.new
    end

    it 'wraps arbitrary methods defined _after_ mixing in' do
      expect(adder.sum(Success(1), Success(2))).to eql(Success(3))
      expect(adder.sum(Success(1), Failure(2))).to eql(Failure(2))
      expect(adder.sum(Failure(1), Success(2))).to eql(Failure(1))
    end

    it 'removes uses a given block' do
      expect(adder.sum(1, 2) { |x| x }).to eql(Success(3))
    end
  end

  it 'wraps already defined method' do
    klass = Class.new {
      def sum(a, b)
        c = yield(a) + yield(b)
        Success(c)
      end
    }.tap { |c|
      c.include mixin
      c.include(result_mixin)
    }

    adder = klass.new

    expect(adder.sum(Success(1), Success(2))).to eql(Success(3))
  end
end
