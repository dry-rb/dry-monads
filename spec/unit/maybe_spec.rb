RSpec.describe(Dry::Monads::Maybe) do
  maybe = described_class

  let(:upcase) { :upcase.to_proc }

  describe maybe::Some do
    subject { described_class.new('foo') }

    let(:upcased_subject) { described_class.new('FOO') }

    it { is_expected.to be_some }
    it { is_expected.not_to be_none }

    it { is_expected.to eq(described_class.new('foo')) }
    it { is_expected.not_to eq(maybe::None.new) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Some("foo")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Some("foo")')
    end

    describe '#bind' do
      it 'accepts a proc and does not lift the result' do
        expect(subject.bind(upcase)).to eql('FOO')
      end

      it 'accepts a block too' do
        expect(subject.bind { |s| s.upcase }).to eql('FOO')
      end

      it 'passes extra arguments to a block' do
        result = subject.bind(:foo) do |value, c|
          expect(value).to eql('foo')
          expect(c).to eql(:foo)
          true
        end

        expect(result).to be true
      end

      it 'passes extra arguments to a proc' do
        proc = -> (value, c) do
          expect(value).to eql('foo')
          expect(c).to eql(:foo)
          true
        end

        result = subject.bind(proc, :foo)

        expect(result).to be true
      end
    end

    describe '#value' do
      it 'returns wrapped value' do
        expect(subject.value).to eql('foo')
      end
    end

    describe '#fmap' do
      it 'accepts a proc and does not lift the result to maybe' do
        expect(subject.fmap(upcase)).to eq(upcased_subject)
      end

      it 'accepts a block too' do
        expect(subject.fmap { |s| s.upcase }).to eq(upcased_subject)
      end

      it 'passes extra arguments to a block' do
        result = subject.fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql('foo')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        expect(result).to eql(maybe::Some.new(true))
      end

      it 'passes extra arguments to a proc' do
        proc = -> (value, c1, c2) do
          expect(value).to eql('foo')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        result = subject.fmap(proc, :foo, :bar)

        expect(result).to eql(maybe::Some.new(true))
      end
    end

    describe '#or' do
      it 'accepts a value as an alternative' do
        expect(subject.or('baz')).to be(subject)
      end

      it 'accepts a block as an alternative' do
        expect(subject.or { fail }).to be(subject)
      end

      it 'ignores all values' do
        expect(subject.or(:foo, :bar, :baz) { fail }).to be(subject)
      end
    end

    describe '#to_maybe' do
      let(:subject) { maybe::Some.new('foo').to_maybe }

      it { is_expected.to eq maybe::Some.new('foo') }
    end
  end

  describe maybe::None do
    subject { described_class.new }

    it { is_expected.not_to be_some }
    it { is_expected.to be_none }

    it { is_expected.to eq(described_class.new) }
    it { is_expected.not_to eq(maybe::Some.new('foo')) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('None')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('None')
    end

    describe '#value' do
      it 'returns wrapped value' do
        expect(subject.value).to be nil
      end
    end

    describe '#bind' do
      it 'accepts a proc and returns itseld' do
        expect(subject.bind(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.bind { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.fmap(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#fmap' do
      it 'accepts a proc and returns itself' do
        expect(subject.fmap(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.fmap { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.fmap(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#or' do
      it 'accepts value as an alternative' do
        expect(subject.or('baz')).to eql('baz')
      end

      it 'accepts block as an alternative' do
        expect(subject.or { 'baz' }).to eql('baz')
      end

      it 'passes extra arguments to a block' do
        result = subject.or(:foo, :bar) do |c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          'baz'
        end

        expect(result).to eql('baz')
      end
    end

    describe '#to_maybe' do
      let(:subject) { maybe::None.new.to_maybe }

      it { is_expected.to eq maybe::None.new }
    end
  end
end
