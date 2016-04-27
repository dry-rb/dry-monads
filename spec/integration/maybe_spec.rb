RSpec.describe(Dry::Monads::Maybe) do
  include Dry::Monads::Maybe::Mixin

  let(:some) { Some(3) }
  let(:none) { None() }

  example 'unwarpping some' do
    expect(some.value).to eq(3)
  end

  example 'unwrapping none' do
    expect(none.value).to be_nil
  end

  context 'bind some' do
    example 'using named method with block' do
      expect(some.bind { |x| x * 2 }).to eql(6)
    end

    example 'using named method with lambda' do
      expect(some.bind -> (x) { x * 2 }).to eql(6)
    end

    example 'using shift operator' do
      expect(some >> -> (x) { x * 2 }).to eql(6)
    end
  end

  context 'bind none' do
    example 'using named method with block' do
      expect(none.bind { |x| x * 2 }).to eql(None())
    end

    example 'using named method with proc' do
      expect(none.bind -> (x) { x * 2 }).to eql(None())
    end

    example 'using shift operator' do
      expect(none >> -> (x) { x * 2 }).to eql(None())
    end
  end

  context 'mapping' do
    context 'some' do
      example 'using block' do
        expect(some.fmap { |x| x * 2 }).to eq(Some(6))
      end

      example 'using proc' do
        expect(some.fmap -> (x) { x * 2 }).to eq(Some(6))
      end
    end

    context 'none' do
      example 'using block' do
        expect(none.fmap { |x| x * 2 }).to eql(None())
      end

      example 'using proc' do
        expect(none.fmap -> (x) { x * 2 }).to eql(None())
      end
    end
  end

  describe 'None' do
    let(:none) { None() }

    example 'None() returns the object every time' do
      expect(None()).to be(None())
    end

    example 'but you can build None by hand' do
      expect(Dry::Monads::Maybe::Mixin::None.new).to eq(None())
    end
  end

  describe 'chaining' do
    let(:inc) { :succ.to_proc }
    let(:maybe_inc) { -> (x) { Maybe(x.succ) } }

    context 'going happy' do
      example 'using lambda with lifting' do
        expect(some.fmap(inc).fmap(inc).fmap(inc).or(0)).to eq(Some(6))
      end

      example 'using lambda without lifting' do
        expect(some.bind(&maybe_inc).bind { |x| maybe_inc[x] }.or(0)).to eq(Some(5))
      end

      example 'using block' do
        result = some.bind do |x|
          Some(inc[x])
        end.or(0)

        expect(result).to eq(Some(4))
      end
    end

    context 'going unhappy path' do
      example 'using values' do
        expect(none.fmap(inc).or(5)).to eq(5)
      end

      example 'using values in a long chain' do
        expect(none.fmap(inc).or(Some(7).or(0))).to eq(Some(7))
      end

      example 'using block' do
        expect(some.bind(-> (_) { none }).fmap(inc).or { |_| 5 }).to eq(5)
      end
    end
  end
end
