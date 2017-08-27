RSpec.describe(Dry::Monads::Either) do
  either = described_class
  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)
  left = either::Left.method(:new)
  right = either::Right.method(:new)

  let(:upcase) { :upcase.to_proc }

  describe either::Right do
    subject { right['foo'] }

    let(:upcased_subject) { right['FOO'] }

    it { is_expected.to be_right }
    it { is_expected.to be_success }

    it { is_expected.not_to be_left }
    it { is_expected.not_to be_failure }

    it { is_expected.to eql(described_class.new('foo')) }
    it { is_expected.not_to eql(left['foo']) }

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

    describe '#either' do
      subject do
        either::Right.new('Foo').either(
          lambda { |v| v.downcase },
          lambda { |v| v.upcase }
        )
      end

      it { is_expected.to eq('FOO') }
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

    describe '#or_fmap' do
      it 'accepts value as an alternative' do
        expect(subject.or_fmap('baz')).to be(subject)
      end

      it 'accepts block as an alternative' do
        expect(subject.or_fmap { fail }).to be(subject)
      end

      it 'ignores all values' do
        expect(subject.or_fmap(:foo, :bar, :baz) { fail }).to be(subject)
      end
    end

    describe '#to_either' do
      subject { either::Right.new('foo').to_either }

      it 'returns self' do
        is_expected.to eql(either::Right.new('foo'))
      end
    end

    describe '#to_maybe' do
      subject { either::Right.new('foo').to_maybe }

      it { is_expected.to be_an_instance_of maybe::Some }
      it { is_expected.to eql(some['foo']) }

      context 'value is nil' do
        around { |ex| suppress_warnings { ex.run } }
        subject { either::Right.new(nil).to_maybe }

        it { is_expected.to be_an_instance_of maybe::None }
        it { is_expected.to eql(maybe::None.new) }
      end
    end

    describe '#tee' do
      it 'passes through itself when the block returns a Right' do
        expect(subject.tee(->(*) { either::Right.new('ignored') })).to eql(subject)
      end

      it 'returns the block result when it is a left' do
        expect(subject.tee(->(*) { either::Left.new('failure') }))
          .to be_an_instance_of either::Left
      end
    end

    describe '#value_or' do
      it 'returns existing value' do
        expect(subject.value_or('baz')).to eql(subject.value)
      end

      it 'ignores a block' do
        expect(subject.value_or { 'baz' }).to eql(subject.value)
      end
    end

    context 'keyword values' do
      subject { either::Right.new(foo: 'foo') }
      let(:struct) { Class.new(Hash)[bar: 'foo'] }

      describe '#bind' do
        it 'passed extra keywords to block along with value' do
          result = subject.bind(bar: 'bar') do |foo:, bar: |
            expect(foo).to eql('foo')
            expect(bar).to eql('bar')
            true
          end

          expect(result).to be true
        end

        it "doesn't use destructuring if it's not needed" do
          expect(right.(struct).bind { |x| x }.class).to be(struct.class)
          expect(right.(struct).bind(nil, bar: 1) { |x| x }.class).to be(struct.class)
        end
      end
    end

    context 'mixed values' do
      subject { either::Right.new(foo: 'foo', 'bar' => 'bar') }

      describe '#bind' do
        it 'passed extra keywords to block along with value' do
          result = subject.bind(:baz, quux: 'quux') do |value, baz, quux: |
            expect(value).to eql(subject.value)
            expect(baz).to eql(:baz)
            expect(quux).to eql('quux')
            true
          end

          expect(result).to be true
        end

        example 'keywords from value takes precedence' do
          result = subject.bind(foo: 'bar', bar: 'bar') do |foo:, bar: |
            expect(foo).to eql('foo')
            expect(bar).to eql('bar')
            true
          end

          expect(result).to be true
        end
      end
    end

    describe '#flip' do
      it 'transforms Right to Left' do
        expect(subject.flip).to eql(left['foo'])
      end
    end

    describe '#ap' do
      subject { right[:upcase.to_proc] }

      it 'applies a wrapped function' do
        expect(subject.apply(right['foo'])).to eql(right['FOO'])
        expect(subject.apply(left['foo'])).to eql(left['foo'])
      end
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

    describe '#either' do
      subject do
        either::Left.new('Foo').either(
          lambda { |v| v.downcase },
          lambda { |v| v.upcase }
        )
      end

      it { is_expected.to eq('foo') }
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

    describe '#or_fmap' do
      it 'maps an alternative' do
        expect(subject.or_fmap('baz')).to eql(right['baz'])
      end

      it 'accepts a block' do
        expect(subject.or_fmap { 'baz' }).to eql(right['baz'])
      end

      it 'passes extra arguments to a block' do
        result = subject.or_fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql('bar')
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          'baz'
        end

        expect(result).to eql(right['baz'])
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

    describe '#tee' do
      it 'accepts a proc and returns itself' do
        expect(subject.tee(upcase)).to be subject
      end

      it 'accepts a block and returns itseld' do
        expect(subject.tee { |s| s.upcase }).to be subject
      end

      it 'ignores arguments' do
        expect(subject.tee(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#flip' do
      it 'transforms Left to Right' do
        expect(subject.flip).to eql(right['bar'])
      end
    end

    describe '#value_or' do
      it 'returns passed value' do
        expect(subject.value_or('baz')).to eql('baz')
      end

      it 'executes a block' do
        expect(subject.value_or { |bar| 'foo' + bar }).to eql('foobar')
      end
    end

    describe '#ap' do
      it 'does nothing' do
        expect(subject.apply(right['foo'])).to be(subject)
        expect(subject.apply(left['foo'])).to be(subject)
      end
    end
  end
end
