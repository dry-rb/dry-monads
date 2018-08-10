RSpec.describe(Dry::Monads::List) do
  list = described_class

  context 'mapping a block' do
    it 'maps a block over list values' do
      expect(list[1, 2, 3].fmap { |v| v + 1 }).to eql(list[2, 3, 4])
    end
  end

  context 'binding a block' do
    it 'binds a block' do
      expect(list[1, 2, 3].bind { |v| [v + 1, v + 2] }).to eql(list[2, 3, 3, 4, 4, 5])
    end
  end

  describe(described_class::Mixin) do
    subject { Class.new { include Dry::Monads::List::Mixin } }

    it 'adds List constructor' do
      expect(subject.new.List([1])).to eql(list[1])
    end
  end

  describe list::Validated do
    include Dry::Monads::Validated::Mixin

    it 'traverses errors' do
      errors = list::Validated[
        Invalid(:no_email), Invalid(:no_name)
      ]

      expect(errors.traverse).to eql(Invalid(list[:no_email, :no_name]))
    end

    it 'traverses valids' do
      errors = list::Validated[
        Valid('john@doe.me'), Valid('John')
      ]

      expect(errors.traverse).to eql(Valid(list["john@doe.me", "John"]))
    end

    context 'when there are valid and invalid items' do
      it 'traverses errors' do
        errors = list::Validated[
          Valid('John'), Invalid(:no_email), Valid('Doe'), Invalid(:no_name), Valid('john@doe.me')
        ]

        expect(errors.traverse).to eql(Invalid(list[:no_email, :no_name]))
      end
    end
  end
end
