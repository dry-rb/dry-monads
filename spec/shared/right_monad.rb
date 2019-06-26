RSpec.shared_examples_for 'a right monad' do
  describe '#either' do
    it 'returns first function applied to the value' do
      expect(subject.either(-> x { x + 'foo' }, -> x { x + 'bar' })).to eq('foofoo')
    end
  end
end
