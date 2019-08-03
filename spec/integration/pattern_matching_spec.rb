RSpec.describe 'pattern matching' do
  context 'Result' do
    include Dry::Monads[:result]

    context 'Success' do
      let(:match) { Test::Context.new }

      specify 'destructuring' do
        class Test::Context
          include Dry::Monads[:result]

          def call(value)
            case value
            in Failure(_) then :failure
            in Success(10) then :ten
            in Success(Integer => x) if x.equal?(50) then :fifty
            in Success(100..500 => code) then code
            in Success() then :empty
            in Success(:code, x) then x
            in Success[:status, x] then x
            in Success({ status: x }) then x
            in Success({ code: 200..300 => x }) then x
            end
          end
        end

        expect(match.(Success(10))).to eql(:ten)
        expect(match.(Success(50))).to eql(:fifty)
        expect(match.(Success())).to eql(:empty)
        expect(match.(Success(400))).to eql(400)
        expect(match.(Success([:code, 600]))).to eql(600)
        expect(match.(Success([:status, 600]))).to eql(600)
        expect(match.(Success({ status: 404 }))).to eql(404)
        expect(match.(Success({ code: 204 }))).to eql(204)
      end
    end

    context 'Failure' do
      let(:match) { Test::Context.new }

      specify 'destructuring' do
        class Test::Context
          include Dry::Monads[:result]

          def call(value)
            case value
            in Failure[:not_found, reason] then reason
            in Failure(:error) then :nope
            in Failure() then :unit
            end
          end
        end

        expect(match.(Failure([:not_found, :no]))).to eql(:no)
        expect(match.(Failure(:error))).to eql(:nope)
        expect(match.(Failure())).to eql(:unit)
        expect { match.(Failure(3)) }.to raise_error(NoMatchingPatternError)
      end
    end
  end

  context 'Maybe' do
    include Dry::Monads[:maybe]

    let(:match) { Test::Context.new }

    specify 'destructuring' do
      class Test::Context
        include Dry::Monads[:maybe]

        def call(value)
          case value
          in Some[:foo, x] then x
          in Some(Integer => x) then x
          in None() then :nothing
          end
        end
      end

      expect(match.(Some([:foo, :payload]))).to eql(:payload)
      expect(match.(Some(30))).to eql(30)
      expect(match.(None())).to eql(:nothing)
    end

    specify 'none alt' do
      class Test::Context
        include Dry::Monads[:maybe]

        def call(value)
          case value
          in None then :nothing
          end
        end
      end

      expect(match.(None())).to eql(:nothing)
    end
  end

  context 'List' do
    include Dry::Monads[:list, :maybe]

    let(:match) { Test::Context.new }

    specify 'destructuring' do
      class Test::Context
        include Dry::Monads[:list, :maybe]

        def call(value)
          case value
          in List[Some[:foo, x]] then x
          in List[_, Some(:else)] then :else
          in List[] then :empty
          in List[Integer => x] then x
          in List[Time] | List[Date] then :date_or_time
          in List[String | Symbol] then :string_or_symbol
          in List[*, 5] then 5
          end
        end
      end

      list = Dry::Monads::List

      expect(match.(list[Some([:foo, :payload])])).to eql(:payload)
      expect(match.(list[Some([:foo, :payload]), Some(:else)])).to eql(:else)
      expect(match.(list[])).to eql(:empty)
      expect(match.(list[5])).to eql(5)
      expect(match.(list[Time.now])).to eql(:date_or_time)
      expect(match.(list[Date.today])).to eql(:date_or_time)
      expect(match.(list[:sym])).to eql(:string_or_symbol)
      expect(match.(list['sym'])).to eql(:string_or_symbol)
      expect(match.(list[1, 2, 3, 4, 5])).to eql(5)
    end
  end
end
