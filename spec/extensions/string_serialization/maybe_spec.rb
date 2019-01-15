require 'dry/monads/extensions/string_serialization/maybe'

RSpec.describe(Dry::Monads::Maybe) do
  maybe = described_class

  before { maybe.load_extensions(:string_serialization) }

  describe maybe::Some do
    describe '#to_str!' do
      context 'when internal value responds to #to_str' do
        it 'returns unwrapped result' do
          instance = described_class.new('foo')

          expect(instance.to_str!).to eq('foo')
        end
      end

      context 'when internal value does not respond to #to_str' do
        it 'raises NoMethodError' do
          instance = described_class.new(1)

          expect { instance.to_str! }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe maybe::None do
    describe '#to_str!' do
      it 'returns the empty string' do
        instance = described_class.new
        
        expect(instance.to_str!).to eq('')
      end
    end
  end
end