RSpec.shared_examples_for 'an applicative' do
  describe '.pure' do
    it 'wraps a value with a monad' do
      expect(described_class.pure(1)).to eql(pure_constructor.(1))
    end

    it 'wraps a block' do
      fn = -> x { x + 1 }
      expect(described_class.pure(&fn)).to eql(pure_constructor.(fn))
    end
  end
end
