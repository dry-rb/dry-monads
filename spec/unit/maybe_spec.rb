RSpec.describe(Dry::Monads::Maybe) do
  maybe = described_class
  some = maybe::Some.method(:new)
  none = maybe::None.new
  unit = Dry::Monads::Unit

  let(:upcase) { :upcase.to_proc }

  it_behaves_like 'an applicative' do
    let(:pure) { some }
  end

  describe maybe do
    describe '.to_proc' do
      it 'returns a block for coerce' do
        expect(maybe.to_proc.('foo')).to eql(some['foo'])
        expect(maybe.to_proc.(nil)).to eql(none)
      end
    end
  end

  describe maybe::Some do
    subject { described_class.new('foo') }

    it_behaves_like 'a monad'

    let(:upcased_subject) { described_class.new('FOO') }

    it { is_expected.to be_some }
    it { is_expected.not_to be_none }

    it { is_expected.to eql(described_class.new('foo')) }
    it { is_expected.not_to eql(none) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Some("foo")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Some("foo")')
    end

    describe '.to_proc' do
      it 'returns a constructor block' do
        expect(maybe::Some.to_proc.('foo')).to eql(subject)
      end
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

    describe '#value!' do
      it 'unwraps the value' do
        expect(subject.value!).to eql('foo')
      end
    end

    describe '#fmap' do
      it 'accepts a proc and does not lift the result to maybe' do
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

        expect(result).to eql(some[true])
      end

      it 'passes extra arguments to a proc' do
        proc = lambda do |value, c1, c2|
          expect(value).to eql('foo')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        result = subject.fmap(proc, :foo, :bar)

        expect(result).to eql(some[true])
      end
    end

    describe '#or' do
      it 'accepts a value as an alternative' do
        expect(subject.or(some['baz'])).to be(subject)
      end

      it 'accepts a block as an alternative' do
        expect(subject.or { fail }).to be(subject)
      end

      it 'ignores all values' do
        expect(subject.or(:foo, :bar, :baz) { fail }).to be(subject)
      end
    end

    describe '#or_fmap' do
      it 'accepts a value as an alternative' do
        expect(subject.or_fmap('baz')).to be(subject)
      end

      it 'accepts a block as an alternative' do
        expect(subject.or_fmap { fail }).to be(subject)
      end

      it 'ignores all values' do
        expect(subject.or_fmap(:foo, :bar, :baz) { fail }).to be(subject)
      end
    end

    describe '#value_or' do
      it 'returns existing value' do
        expect(subject.value_or('baz')).to eql(subject.value!)
      end

      it 'ignores a block' do
        expect(subject.value_or { 'baz' }).to eql(subject.value!)
      end
    end

    describe '#to_maybe' do
      let(:subject) { some['foo'].to_maybe }

      it { is_expected.to eql some['foo'] }
    end

    describe '#tee' do
      it 'passes through itself when the block returns a Right' do
        expect(subject.tee(->(*) { some['ignored'] })).to be(subject)
      end

      it 'returns the block result when it is None' do
        expect(subject.tee(->(*) { none })).to be_none
      end
    end

    describe '#some?/#success?' do
      it 'returns true' do
        expect(subject).to be_some
        expect(subject).to be_success
      end
    end

    describe '#none?/#failure?' do
      it 'returns false' do
        expect(subject).not_to be_none
        expect(subject).not_to be_failure
      end
    end

    describe '#apply' do
      subject { some[:upcase.to_proc] }

      it 'applies a wrapped function' do
        expect(subject.apply(some['foo'])).to eql(some['FOO'])
        expect(subject.apply(none)).to eql(none)
      end
    end

    describe '#===' do
      it 'matches on the wrapped value' do
        expect(some['foo']).to be === some['foo']
        expect(some[/\w+/]).to be === some['foo']
        expect(some[:bar]).not_to be === some['foo']
        expect(some[10..50]).to be === some[42]
      end
    end

    describe '#discard' do
      it 'nullifies the value' do
        expect(some['foo'].discard).to eql(some[unit])
      end
    end
  end

  describe maybe::None do
    subject { described_class.new }

    it_behaves_like 'a monad'

    it { is_expected.not_to be_some }
    it { is_expected.to be_none }

    it { is_expected.to eql(described_class.new) }
    it { is_expected.not_to eql(some['foo']) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('None')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('None')
    end

    describe '#initialize' do
      it 'traces the caller' do
        expect(subject.trace).to include("spec/unit/maybe_spec.rb")
      end
    end

    describe '#value!' do
      it 'raises an error' do
        expect { subject.value! }.to raise_error(Dry::Monads::UnwrapError, "value! was called on None")
      end
    end

    describe '#bind' do
      it 'accepts a proc and returns itself' do
        expect(subject.bind(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.bind { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.bind(1, 2, 3) { fail }).to be subject
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
      it 'accepts a value as an alternative' do
        expect(subject.or('baz')).to eql('baz')
      end

      it 'accepts a block as an alternative' do
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

    describe '#or_fmap' do
      it 'maps an alternative' do
        expect(subject.or_fmap('baz')).to eql(some['baz'])
      end

      it 'accepts a block' do
        expect(subject.or_fmap { 'baz' }).to eql(some['baz'])
      end

      it 'passes extra arguments to a block' do
        result = subject.or_fmap(:foo, :bar) do |c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          'baz'
        end

        expect(result).to eql(some['baz'])
      end

      it 'tranforms nil to None' do
        expect(subject.or_fmap(nil)).to eql(none)
      end
    end

    describe '#value_or' do
      it 'returns passed value' do
        expect(subject.value_or('baz')).to eql('baz')
      end

      it 'executes a block' do
        expect(subject.value_or { 'bar' }).to eql('bar')
      end
    end

    describe '#to_maybe' do
      let(:subject) { none.to_maybe }

      it { is_expected.to eql maybe::None.new }
    end

    describe '#tee' do
      it 'accepts a proc and returns itself' do
        expect(subject.tee(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.tee { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.tee(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#some?/#success?' do
      it 'returns true' do
        expect(subject).not_to be_some
        expect(subject).not_to be_success
      end
    end

    describe '#none?/#failure?' do
      it 'returns false' do
        expect(subject).to be_none
        expect(subject).to be_failure
      end
    end

    describe '#apply' do
      it 'does nothing' do
        expect(subject.apply(some['foo'])).to be(subject)
        expect(subject.apply(none)).to be(subject)
      end
    end

    describe '#===' do
      it 'matches against other None' do
        expect(none).to be === maybe::None.new
      end

      it "doesn't match a Some" do
        expect(none).not_to be === some['foo']
      end
    end

    describe '#discard' do
      it 'returns self back' do
        expect(none.discard).to be none
      end
    end
  end

  describe maybe::Mixin do
    subject(:obj) { Object.new.tap { |o| o.extend(maybe::Mixin) } }

    describe '#Some' do
      example 'with plain value' do
        expect(subject.Some('thing')).to eql(some['thing'])
      end

      example 'with a block' do
        block = -> { 'thing' }
        expect(subject.Some(&block)).to eql(some[block])
      end

      it 'raises an ArgumentError on missing value' do
        expect(subject.Some()).to eql(some[unit])
      end
    end

    describe '#None' do
      example 'tracks the caller' do
        expect(subject.None().trace).to include("spec/unit/maybe_spec.rb")
      end
    end
  end
end
