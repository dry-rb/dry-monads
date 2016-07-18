RSpec.describe(Dry::Monads::Either) do
  include Dry::Monads::Either::Mixin
  include Dry::Monads::Maybe::Mixin

  context 'going happy path' do
    let(:right) { Right(message: 'success') }

    context 'using map' do
      example 'with block' do
        result = right.fmap do |_|
          { message: 'happy' }
        end

        expect(result.value).to eql(message: 'happy')
      end

      example 'with proc' do
        result = right.fmap(-> (_) { { message: 'happy' } })

        expect(result.value).to eql(message: 'happy')
      end
    end

    context 'using bind' do
      example 'with block' do
        result = right.bind do |_|
          Right(message: 'happy')
        end

        expect(result.value).to eql(message: 'happy')
      end

      example 'with proc' do
        result = right.bind(-> (_) { Right(message: 'happy') })

        expect(result.value).to eql(message: 'happy')
      end
    end
  end

  context 'going unhappy path' do
    let(:left) { Left(error: 'failure') }

    example 'with block' do
      result = left.or do |h|
        { error: 'Error: ' + h.fetch(:error) }
      end

      expect(result).to eql(error: 'Error: failure')
    end

    example 'with value' do
      result = left.or('Error')

      expect(result).to eql('Error')
    end
  end

  context 'chaining procs' do
    let(:right) { Right(0) }

    context 'using map' do
      let(:inc) { :succ.to_proc }

      example 'with happy path' do
        result = right.fmap(inc).or(-1).fmap(inc).or(-2)

        expect(result.value).to eql(2)
      end
    end

    context 'using bind' do
      let(:inc) { -> v { Right(v.succ) } }
      let(:failed_inc) { -> _ { Left(0) } }

      example 'with happy path' do
        result = right.bind(inc).or(-1).bind(inc).or(-2)

        expect(result.value).to eql(2)
      end

      example 'with unhappy path' do
        result = right.bind(inc).or(-1).bind(failed_inc).or(-2)

        expect(result).to eq(-2)
      end

      context 'reduce list of operations' do
        example 'with happy path' do
          result = [inc, inc, inc].reduce(right, :bind)

          expect(result).to eq(Right(3))
        end

        example 'with unhappy path' do
          result = [inc, inc, failed_inc, inc].reduce(right, :bind)

          expect(result).to eq(Left(0))
        end
      end
    end
  end

  context 'chaining blocks' do
    let(:right) { Right(value: 0) }

    example 'big happy chain' do
      result = right.fmap do |r|
        { value: r[:value] + 1 }
      end.bind do |r|
        Right(value: r[:value] + 1) if r[:value] > 0
      end.or do
        Left('error')
      end

      expect(result.value).to eql(value: 2)
    end

    example 'big unhappy chain' do
      result = right.bind do |r|
        Right(value: r[:value] + 1)
      end.bind do |r|
        Left(value: -r[:value] - 1)
      end.bind do |r|
        Right(value: r[:value] + 2)
      end

      expect(result).to eq(Left(value: -2))
    end
  end
end
