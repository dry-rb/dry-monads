RSpec.describe(Dry::Monads::Validated) do
  validated = described_class
  valid = described_class::Valid.method(:new)
  invalid = described_class::Invalid.method(:new)

  it_behaves_like 'an applicative' do
    let(:pure) { valid }
  end

  describe '.pure' do
    it 'constructs a Valid value' do
      expect(validated.pure(1)).to eql(valid.(1))
    end
  end

  describe validated::Valid do
    subject { valid.(1) }

    it_behaves_like 'a constructor'
    it_behaves_like 'a functor'

    describe '#inspect' do
      it 'returns the string representation' do
        expect(subject.inspect).to eql("Valid(1)")
      end
    end

    describe '#fmap' do
      it 'lifts a block' do
        expect(subject.fmap { |value| (value + 1).to_s }).to eql(valid.("2"))
      end
    end

    describe '#value!' do
      it 'extracts the stored value' do
        expect(subject.value!).to eql(1)
      end
    end

    describe '#alt_map' do
      it 'is an inversed fmap' do
        expect(subject.alt_map { fail }).to be(subject)
        expect(subject.alt_map(-> { fail })).to be(subject)
      end
    end

    describe '#or' do
      it 'returns self back' do
        expect(subject.or { fail }).to be(subject)
        expect(subject.or(-> { fail })).to be(subject)
      end
    end
  end

  describe validated::Invalid do
    subject { invalid.(:missing_value) }

    it_behaves_like 'a constructor'

    describe '#inspect' do
      it 'returns the string representation' do
        expect(subject.inspect).to eql("Invalid(:missing_value)")
      end
    end

    describe '#fmap' do
      it 'returns self back' do
        expect(subject.fmap { fail }).to be(subject)
        expect(subject.fmap(-> { fail })).to be(subject)
      end
    end

    describe '#alt_map' do
      it 'is an inversed fmap' do
        expect(subject.alt_map { |value| value.to_s }).to eql(invalid.("missing_value"))
        expect(subject.alt_map(-> value { value.to_s })).to eql(invalid.("missing_value"))
      end
    end

    describe '#error' do
      it 'returns the stored value' do
        expect(subject.error).to eql(:missing_value)
      end
    end

    describe '#or' do
      it 'yields a block' do
        expect(subject.or { :result }).to eql(:result)
        expect(subject.or(-> { :result })).to eql(:result)
      end
    end

    describe '#apply' do
      it 'concatenates errors using +' do
        expect(invalid.(1).apply(invalid.(2))).to eql(invalid.(3))
      end
    end
  end
end
