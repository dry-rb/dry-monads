require 'English'

RSpec.describe(Dry::Monads::Try) do
  try = described_class
  result = Dry::Monads::Result
  success = result::Success.method(:new)
  failure = result::Failure.method(:new)
  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)
  value = try::Value.method(:new)
  div_value = -> v { value[[ZeroDivisionError], v] }
  error = try::Error.method(:new)

  division_error = 1 / 0 rescue $ERROR_INFO
  no_method_error = no_method rescue $ERROR_INFO

  let(:upcase) { :upcase.to_proc }
  let(:divide_by_zero) { -> _value { raise division_error } }

  describe(try::Value) do
    subject { div_value['foo'] }

    let(:upcase_value) { div_value['FOO'] }
    let(:upcase_error) { try::Error.new(division_error) }

    it { is_expected.to be_value }
    it { is_expected.not_to be_error }
    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }

    it { is_expected.to eql(described_class.new([ZeroDivisionError], 'foo')) }
    it { is_expected.not_to eql(error[division_error]) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Try::Value("foo")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Try::Value("foo")')
    end

    describe '#bind' do
      it 'accepts a proc and does not lift the result' do
        expect(subject.bind(upcase)).to eql('FOO')
      end

      it 'accepts a block too' do
        expect(subject.bind { |s| s.upcase }).to eql('FOO')
      end

      it 'captures checked exceptions and return Failure object' do
        expect(subject.bind { raise division_error }).to be_an_instance_of try::Error
      end

      it 'does not rescue unchecked exceptions' do
        expect { subject.bind { |_value| raise no_method_error } }.to raise_error(no_method_error)
      end

      it 'passes extra arguments to a block' do
        tried = subject.bind(:foo) do |v, c|
          expect(v).to eql('foo')
          expect(c).to eql(:foo)
          true
        end

        expect(tried).to be true
      end

      it 'passes extra arguments to a proc' do
        proc = lambda do |v, c|
          expect(v).to eql('foo')
          expect(c).to eql(:foo)
          true
        end

        result = subject.bind(proc, :foo)

        expect(result).to be true
      end
    end

    describe '#fmap' do
      it 'accepts a proc and lifts the result to Success' do
        expect(subject.fmap(upcase)).to eql(upcase_value)
      end

      it 'accepts a proc and lifts the result to Failure' do
        expect(subject.fmap(divide_by_zero)).to eql(upcase_error)
      end

      it 'accepts a block and returns Success' do
        expect(subject.fmap { |s| s.upcase }).to eql(upcase_value)
      end

      it 'accepts a block and returns Failure' do
        expect(subject.fmap { |_s| raise division_error }).to eql(upcase_error)
      end

      it 'passes extra arguments to a block' do
        tried = subject.fmap(:foo, :bar) do |val, c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          val.upcase
        end

        expect(tried).to eql(upcase_value)
      end

      it 'passes extra arguments to a proc' do
        proc = lambda do |val, c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          val.upcase
        end

        tried = subject.fmap(proc, :foo, :bar)

        expect(tried).to eql(upcase_value)
      end
    end

    describe '#to_maybe' do
      it 'transforms self to Some if value is not nil' do
        expect(subject.to_maybe).to eql(some['foo'])
      end

      it 'returns None if value is nil' do
        expect(div_value[nil].to_maybe).to eql(maybe::None.new)
      end
    end

    describe '#to_result' do
      it 'transforms self to Result::Success' do
        expect(subject.to_result).to eql(success['foo'])
      end
    end

    describe '#value_or' do
      it 'returns existing value' do
        expect(subject.value_or('baz')).to eql subject.value!
      end

      it 'ignores a block' do
        expect(subject.value_or { 'baz' }).to eql subject.value!
      end
    end

    describe '#or' do
      it 'returns itself' do
        expect(subject.or { fail }).to be(subject)
      end
    end

    describe '#apply' do
      subject { div_value[:upcase.to_proc] }

      it 'applies a wrapped function' do
        expect(subject.apply(div_value['foo'])).to eql(div_value['FOO'])
        expect(subject.apply(upcase_error)).to eql(upcase_error)
      end
    end

    describe '#===' do
      it 'matches on the wrapped value' do
        expect(div_value[10]).to be === div_value[10]
        expect(div_value[Integer]).to be === div_value[10]
        expect(div_value[String]).not_to be === div_value[10]
      end
    end
  end

  describe(try::Error) do
    subject { described_class.new(division_error) }
    other_error = 1 / 0 rescue $ERROR_INFO

    let(:upcase_value) { described_class.new([ZeroDivisionError], 'FOO') }
    let(:upcase_error) { try::Error.new(division_error) }

    it { is_expected.not_to be_value }
    it { is_expected.to be_error }
    it { is_expected.not_to be_success }
    it { is_expected.to be_failure }

    it { is_expected.to eql(described_class.new(division_error)) }
    it { is_expected.not_to eql(try::Value.new([ZeroDivisionError], 'foo')) }

    # This assertion does not always pass on JRuby, but it's some deep JRuby's internals,
    # so let's just ignore it
    unless defined? JRUBY_VERSION
      it { is_expected.not_to eql(described_class.new(other_error)) }
    end

    it 'dumps to string' do
      expect(subject.to_s).to eql('Try::Error(ZeroDivisionError: divided by 0)')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Try::Error(ZeroDivisionError: divided by 0)')
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
        expect(subject.fmap(divide_by_zero)).to be subject
      end

      it 'ignores arguments' do
        expect(subject.fmap(1, 2, 3) { fail }).to be subject
      end
    end

    describe '#to_maybe' do
      it 'transforms self to None' do
        expect(subject.to_maybe).to eql(maybe::None.new)
      end
    end

    describe '#to_result' do
      it 'transforms self to Result::Failure' do
        expect(subject.to_result).to eql(failure[division_error])
      end
    end

    describe '#value_or' do
      it 'returns passed value' do
        expect(subject.value_or(1)).to eql 1
      end

      it 'executes a block' do
        expect(subject.value_or { 2 + 1 }).to eql 3
      end
    end

    describe '#or' do
      it 'returns yields a block' do
        expect(subject.or { some[1] }).to eql(some[1])
      end
    end

    describe '#apply' do
      it 'does nothing' do
        expect(subject.apply(value[[ZeroDivisionError], 'foo'])).to be(subject)
        expect(subject.apply(error[division_error])).to be(subject)
      end
    end

    describe '#===' do
      it 'matches using the error value' do
        expect(error[division_error]).to be === error[division_error]
        expect(error[ZeroDivisionError]).to be === error[division_error]
      end
    end
  end

  describe try::Mixin do
    subject(:obj) { Object.new.tap { |o| o.extend(try::Mixin) } }

    describe '#Value' do
      example 'with plain value' do
        expect(subject.Value('something')).to eql(value[[StandardError], 'something'])
      end

      example 'with a block' do
        block = -> { 'something' }
        expect(subject.Value(&block)).to eql(value[[StandardError], block])
      end

      it 'raises an ArgumentError on missing value' do
        expect { subject.Value() }.to raise_error(ArgumentError, 'No value given')
      end
    end

    describe '#Error' do
      example 'with plain value' do
        expect(subject.Error(division_error)).to eql(error[division_error])
      end

      example 'with a block' do
        block = -> { 'something' }
        expect(subject.Error(&block)).to eql(error[block])
      end

      it 'raises an ArgumentError on missing value' do
        expect { subject.Error() }.to raise_error(ArgumentError, 'No value given')
      end
    end
  end
end
