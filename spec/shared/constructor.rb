RSpec.shared_examples_for 'a constructor' do
  let(:value) { described_class.new(1) }

  describe '#inspect' do
    it 'returns the string representation' do
      expect(value.inspect).to be_a(String)
    end
  end

  describe '#to_s' do
    it 'is an alias for #inspect' do
      expect(value.method(:to_s)).to eql(value.method(:inspect))
    end
  end
end
