# frozen_string_literal: true

RSpec.describe(Dry::Monads::Try) do
  include Dry::Monads::Try::Mixin

  context 'success' do
    let(:try) { Try { 10 / 2 } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Value)
        expect(try.success?).to eql(true)
        expect(try.failure?).to eql(false)
      end
    end
  end

  context 'failure' do
    let(:try) { Try { 10 / 0 } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Error)
        expect(try.success?).to eql(false)
        expect(try.failure?).to eql(true)
      end
    end
  end

  context 'success value' do
    let(:try) { Try { 10 / 2 } }

    example do
      expect(try.value!).to eql(5)
    end
  end

  context 'failure exception' do
    let(:try) { Try { 10 / 0 } }

    example do
      expect(try.exception).to be_kind_of(ZeroDivisionError)
    end
  end

  context 'bind success' do
    let(:try) { Try { 20 / 10 }.bind ->(number) { Try { 10 / number } } }

    example do
      expect(try.value!).to eql(5)
    end
  end

  context 'bind failure' do
    let(:try) { Try { 20 / 0 }.bind ->(number) { Try { 10 / number } } }

    example do
      expect(try.exception).to be_kind_of(ZeroDivisionError)
    end
  end

  context 'fmap success' do
    let(:try) { Try { 10 / 5 }.fmap { |x| x * 2 } }

    example do
      expect(try.value!).to eql(4)
    end
  end

  context 'fmap failure' do
    let(:try) { Try { 10 / 0 }.fmap { |x| x * 2 } }

    example do
      expect(try.exception).to be_kind_of(ZeroDivisionError)
    end
  end

  context 'to maybe success' do
    let(:try) { Try { 10 / 5 }.to_maybe }

    example do
      expect(try).to eql(Dry::Monads::Some(2))
    end
  end

  context 'to maybe failure' do
    let(:try) { Try { 10 / 0 }.to_maybe }

    example do
      expect(try).to eql(Dry::Monads::None())
    end
  end

  context 'to result success' do
    let(:try) { Try { 10 / 5 }.to_result }

    example do
      expect(try).to eql(Dry::Monads::Success(2))
    end
  end

  context 'to result failure' do
    let(:try) { Try { 10 / 0 }.to_result }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Result::Failure)
        expect(try.failure).to be_kind_of(ZeroDivisionError)
      end
    end
  end

  context 'no exceptions raised when in a list of catchable exceptions' do
    let(:try) { Try(NoMethodError, NotImplementedError) { raise NotImplementedError } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Error)
        expect(try.exception).to be_kind_of(NotImplementedError)
      end
    end
  end

  context 'exception raised if not within a list of catchable exceptions' do
    let(:try) { Try(NoMethodError, NotImplementedError) { 10 / 0 } }

    example do
      aggregate_failures do
        expect { try }.to raise_error(ZeroDivisionError)
      end
    end
  end

  describe 'matching' do
    let(:match) do
      lambda do |value|
        case value
        when Value('foo') then :foo_eql
        when Value(/\w+/) then :bar_rg
        when Value(42) then :int_match
        when Value(10..50) then :int_range
        when Value(-> x { x > 9000 }) then :int_proc_arg
        when Value { |x| x > 100 } then :int_proc_block
        when Error(10) then :ten_eql
        when Error(/\w+/) then :failure_rg
        when Error { |x| x > 90 } then :failure_block
        else
          :else
        end
      end
    end

    it 'can be used in a case statement' do
      expect(match.(Value('foo'))).to eql(:foo_eql)
      expect(match.(Value('bar'))).to eql(:bar_rg)
      expect(match.(Value(42))).to eql(:int_match)
      expect(match.(Value(42.0))).to eql(:int_match)
      expect(match.(Value(12))).to eql(:int_range)
      expect(match.(Value(9123))).to eql(:int_proc_arg)
      expect(match.(Value(144))).to eql(:int_proc_block)
      expect(match.(Error(10))).to eql(:ten_eql)
      expect(match.(Error('foo'))).to eql(:failure_rg)
      expect(match.(Error(100))).to eql(:failure_block)
      expect(match.(Value(-1))).to eql(:else)
    end
  end
end
