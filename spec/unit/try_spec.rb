require 'English'

RSpec.describe(Dry::Monads::Try) do
  try = described_class
  result = Dry::Monads::Result
  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)
  success = try::Success.method(:new)
  div_success = -> value { success[[ZeroDivisionError], value] }
  failure = try::Failure.method(:new)

  division_error = 1 / 0 rescue $ERROR_INFO
  no_method_error = no_method rescue $ERROR_INFO

  let(:upcase) { :upcase.to_proc }
  let(:divide_by_zero) { ->(_value) { raise division_error } }

  describe(try::Success) do
    subject { div_success['foo'] }

    let(:upcase_success) { div_success['FOO'] }
    let(:upcase_failure) { try::Failure.new(division_error) }

    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }

    it { is_expected.to eql(described_class.new([ZeroDivisionError], 'foo')) }
    it { is_expected.not_to eql(failure[division_error]) }

    it 'dumps to string' do
      expect(subject.to_s).to eql('Try::Success("foo")')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Try::Success("foo")')
    end

    describe '#bind' do
      it 'accepts a proc and does not lift the result' do
        expect(subject.bind(upcase)).to eql('FOO')
      end

      it 'accepts a block too' do
        expect(subject.bind { |s| s.upcase }).to eql('FOO')
      end

      it 'captures checked exceptions and return Failure object' do
        expect(subject.bind { raise division_error }).to be_an_instance_of try::Failure
      end

      it 'does not rescue unchecked exceptions' do
        expect { subject.bind { |_value| raise no_method_error } }.to raise_error(no_method_error)
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
      it 'accepts a proc and lifts the result to Success' do
        expect(subject.fmap(upcase)).to eql(upcase_success)
      end

      it 'accepts a proc and lifts the result to Failure' do
        expect(subject.fmap(divide_by_zero)).to eql(upcase_failure)
      end

      it 'accepts a block and returns Success' do
        expect(subject.fmap { |s| s.upcase }).to eql(upcase_success)
      end

      it 'accepts a block and returns Failure' do
        expect(subject.fmap { |_s| raise division_error }).to eql(upcase_failure)
      end

      it 'passes extra arguments to a block' do
        result = subject.fmap(:foo, :bar) do |value, c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          value.upcase
        end

        expect(result).to eql(upcase_success)
      end

      it 'passes extra arguments to a proc' do
        proc = lambda do |value, c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          value.upcase
        end

        result = subject.fmap(proc, :foo, :bar)

        expect(result).to eql(upcase_success)
      end
    end

    describe '#to_maybe' do
      it 'transforms self to Some if value is not nil' do
        expect(subject.to_maybe).to eql(some['foo'])
      end

      it 'returns None if value is nil' do
        expect(div_success[nil].to_maybe).to eql(maybe::None.new)
      end
    end

    describe '#to_result' do
      it 'transforms self to Result::Success' do
        expect(subject.to_result).to eql(result::Success.new('foo'))
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
      subject { div_success[:upcase.to_proc] }

      it 'applies a wrapped function' do
        expect(subject.apply(div_success['foo'])).to eql(div_success['FOO'])
        expect(subject.apply(upcase_failure)).to eql(upcase_failure)
      end
    end
  end

  describe(try::Failure) do
    subject { described_class.new(division_error) }
    other_error = 1 / 0 rescue $ERROR_INFO

    let(:upcase_success) { described_class.new([ZeroDivisionError], 'FOO') }
    let(:upcase_failure) { try::Failure.new(division_error) }

    it { is_expected.not_to be_success }
    it { is_expected.to be_failure }

    it { is_expected.to eql(described_class.new(division_error)) }
    it { is_expected.not_to eql(try::Success.new([ZeroDivisionError], 'foo')) }

    # This assertion does not always pass on JRuby, but it's some deep JRuby's internals,
    # so let's just ignore it
    unless defined? JRUBY_VERSION
      it { is_expected.not_to eql(described_class.new(other_error)) }
    end

    it 'dumps to string' do
      expect(subject.to_s).to eql('Try::Failure(ZeroDivisionError: divided by 0)')
    end

    it 'has custom inspection' do
      expect(subject.inspect).to eql('Try::Failure(ZeroDivisionError: divided by 0)')
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
        expect(subject.to_result).to eql(result::Failure.new(division_error))
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
        expect(subject.apply(success[[ZeroDivisionError], 'foo'])).to be(subject)
        expect(subject.apply(failure[division_error])).to be(subject)
      end
    end
  end
end
