RSpec.shared_examples_for 'a functor' do
  describe '#fmap' do
    it 'accepts a callable' do
      expect(subject.fmap { |v| v.inspect }).to eql(subject.fmap(:inspect.to_proc))
    end
  end
end
