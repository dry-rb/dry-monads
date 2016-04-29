RSpec.describe(Dry::Monads) do
  M = Dry::Monads

  describe 'Maybe' do
    include Dry::Monads::Maybe::Mixin

    context 'some' do
      let(:maybe) { M.Maybe(5) }

      example { expect(maybe).to eq(Some(5)) }
    end

    context 'none' do
      let(:maybe) { M.Maybe(nil) }

      example { expect(maybe).to eq(None()) }
    end

    describe 'Some' do
      subject { M.Some(10) }

      it { is_expected.to be_kind_of(Dry::Monads::Maybe::Some) }
    end

    describe 'None' do
      subject { M.None() }

      it { is_expected.to be_kind_of(Dry::Monads::Maybe::None) }
    end
  end

  describe 'Either' do
    describe 'Right' do
      subject { M.Right("everything went right") }

      it { is_expected.to be_kind_of(Dry::Monads::Either::Right) }
    end

    describe 'Left' do
      subject { M.Left("something has gone wrong") }

      it { is_expected.to be_kind_of(Dry::Monads::Either::Left) }
    end
  end
end
