RSpec.describe(Dry::Monads::Try) do
  include Dry::Monads::Try::Mixin

  context 'success' do
    let(:try) { Try { 10 / 2 } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Success)
        expect(try.success?).to eq(true)
        expect(try.failure?).to eq(false)
      end
    end
  end

  context 'failure' do
    let(:try) { Try { 10 / 0 } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Failure)
        expect(try.success?).to eq(false)
        expect(try.failure?).to eq(true)
      end
    end
  end

  context 'success value' do
    let(:try) { Try { 10 / 2 } }

    example do
      expect(try.value).to eq(5)
    end
  end

  context 'failure exception' do
    let(:try) { Try { 10 / 0 } }

    example do
      expect(try.exception).to be_kind_of(ZeroDivisionError)
    end
  end

  context 'bind success' do
    let(:try) { Try { 20 / 10 } >> -> (number) { Try { 10 / number } } }

    example do
      expect(try.value).to eq(5)
    end
  end

  context 'bind failure' do
    let(:try) { Try { 20 / 0 } >> -> (number) { Try { 10 / number } } }

    example do
      expect(try.exception).to be_kind_of(ZeroDivisionError)
    end
  end

  context 'fmap success' do
    let(:try) { Try { 10 / 5 }.fmap { |x| x * 2 } }

    example do
      expect(try.value).to eq(4)
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
      expect(try).to eq(Dry::Monads::Some(2))
    end
  end

  context 'to maybe failure' do
    let(:try) { Try { 10 / 0 }.to_maybe }

    example do
      expect(try).to eq(Dry::Monads::None())
    end
  end

  context 'to either success' do
    let(:try) { Try { 10 / 5 }.to_either }

    example do
      expect(try).to eq(Dry::Monads::Right(2))
    end
  end

  context 'to either failure' do
    let(:try) { Try { 10 / 0 }.to_either }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Either::Left)
        expect(try.value).to be_kind_of(ZeroDivisionError)
      end
    end
  end

  context 'no exceptions raised when in a list of catchable exceptions' do
    let(:try) { Try(NoMethodError, NotImplementedError) { raise NotImplementedError } }

    example do
      aggregate_failures do
        expect(try).to be_kind_of(Dry::Monads::Try::Failure)
        expect(try.exception).to be_kind_of(NotImplementedError)
      end
    end
  end

  context 'exception raised if not within a list of catchable exceptions' do
    let(:try) { Try(NoMethodError, NotImplementedError) { 10 / 0 } }

    example do
      aggregate_failures do
        expect{ try }.to raise_error(ZeroDivisionError)
      end
    end
  end
end