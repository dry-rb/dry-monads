RSpec.describe(Dry::Monads::Maybe) do
  include Dry::Monads::Maybe::Mixin

  context 'unwarpping some' do
    let(:some) { Some(3).value }

    example do
      expect(some).to eq(3)
    end
  end

  context 'unwrapping none' do
    let(:none) { None().value }

    example do
      expect(none).to be_nil
    end
  end

  context 'bind some' do
    let(:some) { Some(3) >> ->(x) { x * 2 } }

    example do
      expect(some).to eq(6)
    end
  end

  context 'bind none' do
    let(:none) { None() >> ->(x) { x * 2 } }

    example do
      expect(none).to eq(None())
    end
  end

  context 'fmap some' do
    let(:some) { Some(3).fmap { |x| x * 2 } }

    example do
      expect(some).to eq(Some(6))
    end
  end

  context 'fmap none' do
    let(:none) { None().fmap { |x| x * 2 } }

    example do
      expect(none).to eq(None())
    end
  end
end
