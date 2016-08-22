RSpec.describe(Dry::Monads::Either) do
  either = described_class
  maybe = Dry::Monads::Maybe

  let(:upcase) { :upcase.to_proc }

  describe either::Right do
    subject { either::Right.new('foo') }

    let(:upcased_subject) { either::Right.new('FOO') }

    it { is_expected.to be_right }
    it { is_expected.to be_success }

    it { is_expected.not_to be_left }
    it { is_expected.not_to be_failure }

    it { is_expected.to eql(described_class.new('foo')) }
    it { is_expected.not_to eql(either::Left.new('foo')) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Right("foo")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Right("foo")')
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
        proc = lambda do |value, c|
          expect(value).to eql('foo')
          expect(c).to eql(:foo)
          true
        end

        result = subject.bind(proc, :foo)

        expect(result).to be true
      end
    end

    describe '#fmap' do
      it 'accepts a proc and lifts the result to either' do
        expect(subject.fmap(upcase)).to eql(upcased_subject)
      end

      it 'accepts a block too' do
        expect(subject.fmap { |s| s.upcase }).to eql(upcased_subject)
      end

      it 'passes extra arguments to a block' do
        result = subject.fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql('foo')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        expect(result).to eql(either::Right.new(true))
      end

      it 'passes extra arguments to a proc' do
        proc = lambda do |value, c1, c2|
          expect(value).to eql('foo')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        result = subject.fmap(proc, :foo, :bar)

        expect(result).to eql(either::Right.new(true))
      end
    end

    describe '#or' do
      it 'accepts value as an alternative' do
        expect(subject.or('baz')).to be(subject)
      end

      it 'accepts block as an alternative' do
        expect(subject.or { fail }).to be(subject)
      end

      it 'ignores all values' do
        expect(subject.or(:foo, :bar, :baz) { fail }).to be(subject)
      end
    end

    describe '#to_either' do
      let(:subject) { either::Right.new('foo').to_either }

      it 'returns self' do
        is_expected.to eql(either::Right.new('foo'))
      end
    end

    describe '#to_maybe' do
      let(:subject) { either::Right.new('foo').to_maybe }

      it { is_expected.to be_an_instance_of maybe::Some }
      it { is_expected.to eql(maybe::Some.new('foo')) }
    end
  end

  describe either::Left do
    subject { either::Left.new('bar') }

    it { is_expected.not_to be_right }
    it { is_expected.not_to be_success }

    it { is_expected.to be_left }
    it { is_expected.to be_failure }

    it { is_expected.to eql(described_class.new('bar')) }
    it { is_expected.not_to eql(either::Right.new('bar')) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Left("bar")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Left("bar")')
    end

    describe '#bind' do
      it 'accepts a proc and returns itseld' do
        expect(subject.bind(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.bind { |s| s.upcase }).to be subject
      end

      it 'ignores extra arguments' do
        expect(subject.bind(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#fmap' do
      it 'accepts a proc and returns itself' do
        expect(subject.fmap(upcase)).to be subject
      end

      it 'accepts a block and returns itseld' do
        expect(subject.fmap { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.fmap(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#or' do
      it 'accepts a value as an alternative' do
        expect(subject.or('baz')).to eql('baz')
      end

      it 'accepts a block as an alternative' do
        expect(subject.or { 'baz' }).to eql('baz')
      end

      it 'passes extra arguments to a block' do
        result = subject.or(:foo, :bar) do |value, c1, c2|
          expect(value).to eql('bar')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          'baz'
        end

        expect(result).to eql('baz')
      end
    end

    describe '#to_either' do
      let(:subject) { either::Left.new('bar').to_either }

      it 'returns self' do
        is_expected.to eql(either::Left.new('bar'))
      end
    end

    describe '#to_maybe' do
      let(:subject) { either::Left.new('bar').to_maybe }

      it { is_expected.to be_an_instance_of maybe::None }
      it { is_expected.to eql(maybe::None.new) }
    end
  end
end
