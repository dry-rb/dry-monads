RSpec.describe(Dry::Monads::List) do
  list = described_class
  maybe = Dry::Monads::Maybe

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

    it 'requires a block' do
      expect { subject.map }.to raise_error(ArgumentError)
    end
  end

  describe '#first' do
    it 'returns Some for non-empty list' do
      expect(subject.first).to eql(maybe::Some.new(1))
    end

    it 'returns None for an empty list' do
      expect(empty_list.first).to eql(maybe::None.new)
    end
  end

  describe '#last' do
    it 'returns Some for non-empty list' do
      expect(subject.last).to eql(maybe::Some.new(3))
    end

    it 'returns None for an empty list' do
      expect(empty_list.last).to eql(maybe::None.new)
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
end
