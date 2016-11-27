RSpec.describe(Dry::Monads::List) do
  list = described_class

  context 'mapping a block' do
    it 'maps a block over list values' do
      expect(list[1, 2, 3].fmap { |v| v + 1 }).to eql(list[2, 3, 4])
    end
  end

  context 'binding a block' do
    it 'binds a block' do
      expect(list[1, 2, 3].bind { |v| [v + 1, v + 2] }).to eql(list[2, 3, 3, 4, 4, 5])
    end
  end
end
