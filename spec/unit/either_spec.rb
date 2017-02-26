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

    describe '#to_either' do
      subject { either::Right.new('foo').to_either }

      it 'returns self' do
        is_expected.to eql(either::Right.new('foo'))
      end
    end

    describe '#to_maybe' do
      subject { either::Right.new('foo').to_maybe }

      it { is_expected.to be_an_instance_of maybe::Some }
      it { is_expected.to eql(maybe::Some.new('foo')) }

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

    context 'keyword values' do
      subject { either::Right.new(foo: 'foo') }

      describe '#bind' do
        it 'passed extra keywords to block along with value' do
          result = subject.bind(bar: 'bar') do |foo:, bar:|
            expect(foo).to eql('foo')
            expect(bar).to eql('bar')
            true
          end

          expect(result).to be true
        end
      end
    end

    context 'mixed values' do
      subject { either::Right.new(foo: 'foo', 'bar' => 'bar') }

      describe '#bind' do
        it 'passed extra keywords to block along with value' do
          result = subject.bind(:baz, quux: 'quux') do |value, baz, foo:, quux:|
            expect(value).to eql('bar' => 'bar')
            expect(baz).to eql(:baz)
            expect(foo).to eql('foo')
            expect(quux).to eql('quux')
            true
          end

          expect(result).to be true
        end

        example 'keywords from value takes precedence' do
          result = subject.bind(foo: 'bar', bar: 'bar') do |foo:, bar:|
            expect(foo).to eql('foo')
            expect(bar).to eql('bar')
            true
          end

          expect(result).to be true
        end
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
  end

  describe '.traverse' do
    context 'regular enumerable' do
      it 'returns a Right-wrapped array of inner values if all values are Right' do
        subject = [
          either::Right.new(3),
          either::Right.new(2),
          either::Right.new(1),
        ]
        expect(
          either.traverse(subject) {|v| v + 1 }
        ).to eq(
          either::Right.new([4,3,2])
        )
      end

      it 'returns the first Left in array if any are present' do
        subject = [
          either::Right.new(3),
          either::Left.new("two"),
          either::Left.new("one"),
        ]
        expect(
          either.traverse(subject) {|v| v + 1 }
        ).to eq(
          either::Left.new("two")
        )
      end
    end

    context 'lazy + effectful enumerable' do
      it 'returns a Right-wrapped array of inner values if all values are Right' do
        subject = Class.new do
          include Enumerable
          attr_accessor :exhausted
          def each
            raise "Exhausted!" if self.exhausted
            either = Dry::Monads::Either
            yield either::Right.new(3)
            yield either::Right.new(2)
            yield either::Right.new(1)
            self.exhausted = true
          end
        end
        expect(
          either.traverse(subject.new) {|v| v + 1 }
        ).to eq(
          either::Right.new(subject.new.map {|v| v.value + 1})
        )
      end

      it 'returns the first Left in array if any are present' do
        subject = Class.new do
          include Enumerable
          attr_accessor :exhausted
          def each
            raise "Exhausted!" if self.exhausted
            either = Dry::Monads::Either
            yield either::Right.new(3)
            yield either::Left.new("two")
            yield either::Left.new("one")
            self.exhausted = true
          end
        end
        expect(
          either.traverse(subject.new) {|v| v + 1 }
        ).to eq(
          either::Left.new("two")
        )
      end
    end
  end
end
