RSpec.describe(Dry::Monads::Maybe) do
  maybe = Dry::Monads::Maybe

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

      it 'has right shift alias' do
        expect(subject >> upcase).to eql('FOO')
      end
    end

    describe '#fmap' do
      it 'accepts a proc and does not lift the result to maybe' do
        expect(subject.fmap(upcase)).to eq(upcased_subject)
      end

      it 'accepts a block too' do
        expect(subject.fmap { |s| s.upcase }).to eq(upcased_subject)
      end
    end

    describe '#or' do
      it 'accepts a value as an alternative' do
        expect(subject.or('baz')).to be(subject)
      end

      it 'accepts a block as an alternative' do
        expect(subject.or { 'baz' }).to be(subject)
      end
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

   describe '#bind' do
      it 'accepts a proc and returns itseld' do
        expect(subject.bind(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.bind { |s| s.upcase }).to be subject
      end

      it 'has right shift alias' do
        expect(subject >> upcase).to be subject
      end
    end

    describe '#fmap' do
      it 'accepts a proc and returns itself' do
        expect(subject.fmap(upcase)).to be subject
      end

      it 'accepts a block and returns itseld' do
        expect(subject.fmap { |s| s.upcase }).to be subject
      end
    end

    describe '#or' do
      it 'accepts value as an alternative' do
        expect(subject.or('baz')).to eql('baz')
      end

      it 'accepts block as an alternative' do
        expect(subject.or { 'baz' }).to eql('baz')
      end
    end
  end
end
