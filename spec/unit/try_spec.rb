require 'English'

RSpec.describe(Dry::Monads::Try) do
  try = described_class
  either = Dry::Monads::Either
  maybe = Dry::Monads::Maybe

  division_error = 1 / 0 rescue $ERROR_INFO
  no_method_error = no_method rescue $ERROR_INFO

  let(:upcase) { :upcase.to_proc }
  let(:divide_by_zero) { -> (_value) { raise division_error }  }

  describe(try::Success) do
    subject { described_class.new([ZeroDivisionError], 'foo') }

    let(:upcase_success) { described_class.new([ZeroDivisionError], 'FOO') }
    let(:upcase_failure) { try::Failure.new(division_error) }

    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }

    it { is_expected.to eq(described_class.new([ZeroDivisionError], 'foo')) }
    it { is_expected.not_to eq(try::Failure.new(division_error)) }

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
    end

    describe '#fmap' do
      it 'accepts a proc and lifts the result to Success' do
        expect(subject.fmap(upcase)).to eq(upcase_success)
      end

      it 'accepts a proc and lifts the result to Failure' do
        expect(subject.fmap(divide_by_zero)).to eq(upcase_failure)
      end

      it 'accepts a block and returns Success' do
        expect(subject.fmap { |s| s.upcase }).to eq(upcase_success)
      end

      it 'accepts a block and returns Failure' do
        expect(subject.fmap { |_s| raise division_error }).to eq(upcase_failure)
      end
    end

    describe '#to_maybe' do
      it 'transforms self to Some if value is not nil' do
        expect(subject.to_maybe).to eq(maybe::Some.new('foo'))
      end

      it 'returns None if value is nil' do
        expect(described_class.new([ZeroDivisionError], nil).to_maybe).to eq(maybe::None.new)
      end
    end

    describe '#to_either' do
      it 'transforms self to Right' do
        expect(subject.to_either).to eq(either::Right.new('foo'))
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

    it { is_expected.to eq(described_class.new(division_error)) }
    it { is_expected.not_to eq(try::Success.new([ZeroDivisionError], 'foo')) }
    it { is_expected.not_to eq(described_class.new(other_error)) }

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
    end

    describe '#fmap' do
      it 'accepts a proc and returns itself' do
        expect(subject.fmap(upcase)).to be subject
      end

      it 'accepts a block and returns itself' do
        expect(subject.fmap(divide_by_zero)).to be subject
      end
    end

    describe '#to_maybe' do
      it 'transforms self to None' do
        expect(subject.to_maybe).to eq(maybe::None.new)
      end
    end

    describe '#to_either' do
      it 'transforms self to Left' do
        expect(subject.to_either).to eq(either::Left.new(division_error))
      end
    end
  end
end
