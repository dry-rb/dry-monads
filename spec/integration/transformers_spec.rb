RSpec.describe(Dry::Monads::Transformer) do
  list = Dry::Monads::List
  success = Dry::Monads::Result::Success.method(:new)
  failure = Dry::Monads::Result::Failure.method(:new)
  some = Dry::Monads::Maybe::Some.method(:new)
  none = Dry::Monads::Maybe::None.new

  context '2-level composition' do
    context 'List Result String' do
      subject(:value) { list[success.('success'), failure.('failure')] }

      context 'using fmap2' do
        example 'for lifting the block' do
          expect(value.fmap2 { |v| v.upcase }).
            to eql(list[success.('SUCCESS'), failure.('failure')])
        end

        example 'for lifting over the empty list' do
          expect(list[].fmap2 { fail }).to eql(list[])
        end

        example 'with a proc' do
          expect(value.fmap2(-> v { v.upcase })).
            to eql(list[success.('SUCCESS'), failure.('failure')])
        end
      end
    end

    context 'List Maybe Integer' do
      subject(:value) { list[some.(2), none] }

      example 'using fmap2 for lifting the block' do
        expect(value.fmap2 { |v| v + 1 }).
          to eql(list[some.(3), none])
      end
    end

    context 'Result Maybe String' do
      context 'using fmap2' do
        example 'with Success Some' do
          expect(success.(some.('result')).fmap2(&:upcase)).
            to eql(success.(some.('RESULT')))
        end

        example 'with Failure None' do
          expect(failure.(none).fmap2 { fail }).
            to eql(failure.(none))
        end
      end
    end

    context 'Maybe List Integer' do
      context 'using fmap2' do
        example 'with Some' do
          expect(some.(list[1, 2, 3]).fmap2(&:succ)).
            to eql(some.(list[2, 3, 4]))
        end

        example 'with None' do
          expect(none.fmap2 { fail }).
            to eql(none)
        end
      end
    end
  end

  context '3-level composition' do
    context 'list of results' do
      subject(:value) { list[success.(some.('success')),
                             success.(none),
                             failure.(some.('failure')),
                             failure.(none)] }

      context 'using fmap3' do
        example 'lifting a block' do
          expect(value.fmap3 { |v| v.upcase }).
            to eql(list[success.(some.('SUCCESS')), success.(none),
                        failure.(some.('failure')), failure.(none)])
        end

        example 'lifting a proc' do
          expect(value.fmap3(-> v { v.upcase })).
            to eql(list[success.(some.('SUCCESS')), success.(none),
                        failure.(some.('failure')), failure.(none)])
        end
      end
    end
  end
end
