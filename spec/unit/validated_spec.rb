RSpec.describe(Dry::Monads::Validated) do
  validated = described_class
  valid = described_class::Valid.method(:new)
  invalid = described_class::Invalid.method(:new)
  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)

  result = Dry::Monads::Result
  success = result::Success.method(:new)
  failure = result::Failure.method(:new)

  it_behaves_like 'an applicative' do
    let(:pure) { valid }
  end

  describe '.pure' do
    it 'constructs a Valid value' do
      expect(validated.pure(1)).to eql(valid.(1))
    end

    it 'accepts a block' do
      fn = -> x { x }
      expect(validated.pure(&fn)).to eql(valid.(fn))
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

    describe '#to_maybe' do
      it 'returns Some' do
        expect(subject.to_maybe).to eql(some.(1))
      end
    end

    describe '#to_result' do
      it 'retuns Success' do
        expect(subject.to_result).to eql(success.(1))
      end
    end

    describe '#===' do
      it 'matches on the wrapped value' do
        expect(valid['foo']).to be === valid['foo']
        expect(valid[/\w+/]).to be === valid['foo']
        expect(valid[:bar]).not_to be === valid['foo']
        expect(valid[10..50]).to be === valid[42]
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

      it 'traces the caller' do
        expect(subject.alt_map { |x| x }.trace).to include("validated_spec.rb")
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

    describe '#to_maybe' do
      it 'returns None' do
        expect(subject.to_maybe).to be_none
      end

      it 'traces the caller' do
        expect(subject.to_maybe.trace).to include("spec/unit/validated_spec.rb")
      end
    end

    describe '#to_result' do
      it 'retuns Failure' do
        expect(subject.to_result).to eql(failure.(:missing_value))
      end

      it 'traces the caller' do
        expect(subject.to_result.trace).to include("spec/unit/validated_spec.rb")
      end
    end

    describe '#===' do
      it 'matches on the wrapped value' do
        expect(invalid['foo']).to be === invalid['foo']
        expect(invalid[/\w+/]).to be === invalid['foo']
        expect(invalid[:bar]).not_to be === invalid['foo']
        expect(invalid[10..50]).to be === invalid[42]
      end
    end
  end

  describe '#bind' do
    it 'tells that Validated has no monad instance' do
      expect {
        valid.(1).bind { fail }
      }.to raise_error(
             NotImplementedError,
             "Validated is not a monad because it would violate the monad laws"
           )
    end
  end
end
