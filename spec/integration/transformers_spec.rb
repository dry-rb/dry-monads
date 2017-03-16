RSpec.describe(Dry::Monads::Transformer) do
  list = Dry::Monads::List
  right = Dry::Monads::Either::Right.method(:new)
  left = Dry::Monads::Either::Left.method(:new)
  some = Dry::Monads::Maybe::Some.method(:new)
  none = Dry::Monads::Maybe::None.new

  context '2-level composition' do
    context 'List Either String' do
      subject(:value) { list[right.('success'), left.('failure')] }

      context 'using fmap2' do
        example 'for lifting the block' do
          expect(value.fmap2 { |v| v.upcase }).
            to eql(list[right.('SUCCESS'), left.('failure')])
        end

        example 'for lifting over the empty list' do
          expect(list[].fmap2 { fail }).to eql(list[])
        end

        example 'with a proc' do
          expect(value.fmap2(-> v { v.upcase })).
            to eql(list[right.('SUCCESS'), left.('failure')])
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

    context 'Either Maybe String' do
      context 'using fmap2' do
        example 'with Right Some' do
          expect(right.(some.('result')).fmap2(&:upcase)).
            to eql(right.(some.('RESULT')))
        end

        example 'with Left None' do
          expect(left.(none).fmap2 { fail }).
            to eql(left.(none))
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
    context 'list of eithers' do
      subject(:value) { list[right.(some.('success')),
                             right.(none),
                             left.(some.('failure')),
                             left.(none)] }

      context 'using fmap3' do
        example 'lifting a block' do
          expect(value.fmap3 { |v| v.upcase }).
            to eql(list[right.(some.('SUCCESS')), right.(none),
                        left.(some.('failure')), left.(none)])
        end

        example 'lifting a proc' do
          expect(value.fmap3(-> v { v.upcase })).
            to eql(list[right.(some.('SUCCESS')), right.(none),
                        left.(some.('failure')), left.(none)])
        end
      end
    end
  end
end
