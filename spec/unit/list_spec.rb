RSpec.describe(Dry::Monads::List) do
  list = described_class

  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)
  none = maybe::None.new

  either = Dry::Monads::Either
  left = either::Left.method(:new)
  right = either::Right.method(:new)

  subject { list[1, 2, 3] }
  let(:empty_list) { list[] }

  describe '.coerce' do
    let(:array_like) do
      Object.new.tap do |o|
        def o.to_ary
          %w(a b c)
        end
      end
    end

    it 'coerces nil to an empty list' do
      expect(list.coerce(nil)).to eql(list.new([]))
    end

    it 'coerces an array' do
      expect(list.coerce([1, 2])).to eql(list.new([1, 2]))
    end

    it 'coerces any array-like object' do
      expect(list.coerce(array_like)).to eql(list.new(%w(a b c)))
    end

    it 'raises a type error on uncoercible object' do
      expect {
        list.coerce(Object.new)
      }.to raise_error(TypeError, /Can't coerce/)
    end
  end

  describe '#inspect' do
    it 'dumps list to a string' do
      expect(subject.inspect).to eql('List[1, 2, 3]')
    end
  end

  describe '#to_s' do
    it 'dumps list to a string' do
      expect(subject.to_s).to eql('List[1, 2, 3]')
    end

    it 'acts as #inspect' do
      expect(subject.to_s).to eql(subject.inspect)
    end

    it 'shows type' do
      expect(list[right.(true)].typed.to_s).to eql('List<Either>[Right(true)]')
    end
  end

  describe '#==' do
    it 'compares two lists' do
      expect(subject).to eq(list[1, 2, 3])
    end
  end

  describe '#eql?' do
    it 'compares two lists with hash equality' do
      expect(subject).to eql(list[1, 2, 3])
    end
  end

  describe '#+' do
    it 'concatenates two lists' do
      expect(subject).to eql(list[1, 2] + list[3])
    end

    it 'coerces an argument' do
      expect(subject + [4, 5]).to eql(list[1, 2, 3, 4, 5])
    end
  end

  describe '#to_a' do
    it 'coerces to an array' do
      expect(subject.to_a).to eql([1, 2, 3])
    end
  end

  describe '#to_ary' do
    it 'coerces to an array' do
      expect(subject.to_ary)
    end

    it 'allows to split a list' do
      a, *b = subject
      expect(a).to eql(1)
      expect(b).to eql([2, 3])
    end
  end

  describe '#bind' do
    it 'binds a block' do
      expect(subject.bind { |x| [x * 2] }).to eql(list[2, 4, 6])
    end

    it 'binds a proc' do
      expect(subject.bind(-> x { [x * 2] })).to eql(list[2, 4, 6])
    end
  end

  describe '#fmap' do
    it 'maps a block' do
      expect(subject.fmap { |x| x * 2 }).to eql(list[2, 4, 6])
    end

    it 'maps a proc' do
      expect(subject.fmap(-> x { x * 2 })).to eql(list[2, 4, 6])
    end
  end

  describe '#map' do
    it 'maps a block over a list' do
      expect(subject.map { |x| x * 2 }).to eql(list[2, 4, 6])
    end

    it 'returns an enumerator if no block given' do
      expect(subject.map).to be_a(Enumerator)
      expect(subject.map.with_index { |el, idx|  [el, idx] }).
        to eql([[1, 0], [2, 1], [3, 2]])
    end
  end

  describe '#first' do
    it 'returns first value for non-empty list' do
      expect(subject.first).to eql(1)
    end

    it 'returns nil for an empty list' do
      expect(empty_list.first).to be_nil
    end
  end

  describe '#last' do
    it 'returns value for non-empty list' do
      expect(subject.last).to eql(3)
    end

    it 'returns nil for an empty list' do
      expect(empty_list.last).to be_nil
    end
  end

  describe '#fold_left' do
    it 'returns initial value for the empty list' do
      expect(empty_list.fold_left(100) { fail }).to eql(100)
    end

    it 'folds from the left' do
      expect(subject.fold_left(0) { |x, y| x - y }).to eql(-6)
    end
  end

  describe '#foldl' do
    it 'is an ailas for fold_left' do
      expect(subject.foldl(0) { |x, y| x - y }).to eql(-6)
    end
  end

  describe '#reduce' do
    it 'is an ailas for fold_left' do
      expect(subject.reduce(0) { |x, y| x - y }).to eql(-6)
    end

    it 'acts as Array#reduce' do
      expect(subject.reduce(0) { |x, y| x - y }).to eql([1, 2, 3].reduce(0) { |x, y| x - y })
    end
  end

  describe '#fold_right' do
    it 'returns initial value for the empty list' do
      expect(empty_list.fold_right(100) { fail }).to eql(100)
    end

    it 'folds from the right' do
      expect(subject.fold_right(0) { |x, y| x - y }).to eql(2)
    end
  end

  describe '#foldr' do
    it 'is an ailas for fold_right' do
      expect(subject.foldr(0) { |x, y| x - y }).to eql(2)
    end
  end

  describe '#empty?' do
    it 'returns false for a non-empty list' do
      expect(subject).not_to be_empty
    end

    it 'returns true for an empty list' do
      expect(empty_list).to be_empty # what a surprise
    end
  end

  describe '#sort' do
    it 'sorts a list' do
      expect(list[3, 2, 1].sort).to eql(subject)
    end
  end

  describe '#filter' do
    it 'filters with a block' do
      expect(subject.filter(&:odd?)).to eql(list[1, 3])
    end
  end

  describe '#select' do
    it 'is an alias for filter' do
      expect(subject.select(&:odd?)).to eql(list[1, 3])
    end
  end

  describe '#size' do
    it 'returns list size' do
      expect(subject.size).to eql(3)
    end
  end

  describe '#reverse' do
    it 'reverses the list' do
      expect(subject.reverse).to eql(list[3, 2, 1])
    end
  end

  describe '#head' do
    it 'returns the first element' do
      expect(subject.head).to eql(some[1])
    end

    it 'returns None for an empty list' do
      expect(empty_list.head).to eql(none)
    end
  end

  describe '#tail' do
    it 'drop the first element' do
      expect(subject.tail).to eql(list[2, 3])
    end

    it 'returns an empty list for a list with one item' do
      expect(list[1].tail).to eql(empty_list)
    end

    it 'returns an empty list for an empty_list' do
      expect(empty_list.tail).to eql(empty_list)
    end
  end

  describe '#traverse' do
    context 'list of eithers' do
      subject { list[1, 2, 3].typed(either) }

      it 'flips Rights' do
        expect(subject.traverse { |x| right.(x + 1) }).to eql(right.(list[2, 3, 4]))
      end

      it 'halts on Left' do
        expect(subject.traverse { |i| i == 2 ? left.(i) : right.(i) }).
          to eql(left.(2))
      end

      it 'halts on first Left' do
        expect(subject.traverse { |i| i > 1 ? left.(i) : right.(i) }).
          to eql(left.(2))
      end

      it 'works without a block' do
        expect(list[right.(1), left.(2), left.(3)].typed.traverse).to eql(left.(2))
      end
    end

    context 'list of maybes' do
      subject { list[1, 2, 3].typed(maybe) }

      it 'flips Somes' do
        expect(subject.traverse { |x| some.(x + 1) }).to eql(some.(list[2, 3, 4]))
      end

      it 'halts on None' do
        expect(subject.traverse { |i| i == 2 ? none : some.(i) }).
          to eql(none)
      end

      it 'halts on first None' do
        expect(subject.traverse { |i| i == 1 ? none : fail }).
          to eql(none)
      end
    end

    context 'list of lists' do
      subject { list[1, 2].typed(list) }

      it 'flips a list' do
        expect(subject.traverse { |x| list[x] }).
          to eql(list[list[1, 2]])

        expect(subject.traverse { |x| list[x, x + 1] }).
          to eql(list[list[1, 2], list[1, 3], list[2, 2], list[2, 3]])
      end
    end

    it 'raises an error for untyped list' do
      expect { subject.traverse }.to raise_error(StandardError, /Cannot traverse/)
    end
  end

  describe '#typed' do
    it 'turns the list into a typed one' do
      expect(subject.typed(either)).to be_typed
      expect(subject.typed(either).type).to be either
    end

    it 'infers type for not empty list' do
      expect(list[right.(1)].typed.type).to be either
      expect(list[left.(1)].typed.type).to be either
      expect(list[some.(1)].typed.type).to be maybe
      expect(list[none].typed.type).to be maybe
      expect(list[list[]].typed.type).to be list
    end

    it 'cannot guess a type of the empty list' do
      expect { list[].typed }.to raise_error(ArgumentError, /Cannot infer/)
    end
  end
end
