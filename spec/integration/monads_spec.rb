RSpec.describe(Dry::Monads) do
  let(:m) { described_class }
  either = Dry::Monads::Either
  maybe = Dry::Monads::Maybe

  describe 'maybe monad' do
    describe '.Maybe' do
      describe 'lifting to Some' do
        subject { m.Some(5) }

        it { is_expected.to eq maybe::Some.new(5) }
      end

      describe 'lifting to None' do
        subject { m.Maybe(nil) }

        it { is_expected.to eq maybe::None.new }
      end
    end

    describe '.Some' do
      subject { m.Some(10) }

      it { is_expected.to eq maybe::Some.new(10) }

      example 'lifting nil produces an error' do
        expect { m.Some(nil) }.to raise_error(ArgumentError)
      end
    end

    describe '.None' do
      subject { m.None() }

      it { is_expected.to eq maybe::None.new }
    end
  end

  describe 'either monad' do
    describe '.Right' do
      subject { m.Right('everything went right') }

      it { is_expected.to eq either::Right.new('everything went right') }
    end

    describe '.Left' do
      subject { m.Left('something has gone wrong') }

      it { is_expected.to eq either::Left.new('something has gone wrong') }
    end
  end
end
