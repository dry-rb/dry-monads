RSpec.describe(Dry::Monads::Do) do
  include Dry::Monads
  include Dry::Monads::Try::Mixin
  include Dry::Monads::List::Mixin

  before do
    module Test
      class Operation
        include Dry::Monads::Do.for(:call)
        include Dry::Monads
        include Dry::Monads::Try::Mixin
        include Dry::Monads::List::Mixin
      end
    end
  end

  let(:klass) { Test::Operation }

  let(:instance) { klass.new }

  context 'with Result' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Success(1)
            m2 = Success(2)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Success(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = Failure(:no_one)
            m2 = Success(2)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns failure' do
        expect(instance.call).to eql(Failure(:no_one))
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Success(1)
            m2 = Failure(:no_two)

            one = yield m1
            two = yield m2

            Success(one + two)
          end
        end
      end

      it 'returns failure' do
        expect(instance.call).to eql(Failure(:no_two))
      end
    end

    context 'with stateful blocks' do
      before do
        klass.class_eval do
          attr_reader :rolled_back

          def initialize
            @rolled_back = false
          end

          def call
            m1 = Success(1)
            m2 = Failure(:no_two)

            transaction do
              one = yield m1
              two = yield m2

              Success(one + two)
            end
          end

          def transaction
            yield
          rescue => e
            @rolled_back = true
            raise e
          end
        end
      end

      it 'halts the executing with an exception' do
        expect(instance.call).to eql(Failure(:no_two))
        expect(instance.rolled_back).to be(true)
      end
    end
  end

  context 'with Maybe' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Some(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = None()
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns none' do
        expect(instance.call).to be_none
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = None()

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns none' do
        expect(instance.call).to be_none
      end
    end
  end

  context 'with Try' do
    context 'successful case' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns the result of a statement' do
        expect(instance.call).to eql(Dry::Monads::Try::pure(3))
      end
    end

    context 'first failure' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 / 0 }
            m2 = Try { 2 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns Error' do
        expect(instance.call).to be_error
      end
    end

    context 'second failure' do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 / 0 }

            Dry::Monads::Try::pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it 'returns Error' do
        expect(instance.call).to be_error
      end
    end
  end

  context 'yielding arrays' do
    context 'success' do
      before do
        klass.class_eval do
          def call
            result = yield [Success(1), Success(2)]

            Success(result)
          end
        end
      end

      it 'casts the given array to a list, infers the monad instance and traverses the list' do
        expect(instance.call).to eql(Success(List([1, 2])))
      end
    end

    context 'failure' do
      before do
        klass.class_eval do
          def call
            result = yield [Success(0), Failure(1), Failure(2)]

            Success(result)
          end
        end
      end

      it 'returns the first failure case' do
        expect(instance.call).to eql(Failure(1))
      end
    end
  end

  context 'yielding lists' do
    context 'success' do
      before do
        class Test::Operation
          def call
            result = yield List::Result[Success(1), Success(2)]

            Success(result)
          end
        end
      end

      it 'casts the given array to a list, infers the monad instance and traverses the list' do
        expect(instance.call).to eql(Success(List([1, 2])))
      end
    end

    context 'failure' do
      before do
        class Test::Operation
          def call
            result = yield List::Result[Success(0), Failure(1), Failure(2)]

            Success(result)
          end
        end
      end

      it 'returns the first failure case' do
        expect(instance.call).to eql(Failure(1))
      end
    end
  end

  context 'implicit conversions' do
    before do
      class Test::ValidationResult
        def to_monad
          Dry::Monads::Success(:converted)
        end
      end

      class Test::Operation
        def call(obj)
          result = yield(obj)

          Success(result)
        end
      end
    end

    it 'implicitly converts an arbitrary object to a monad' do
      result = Test::ValidationResult.new
      expect(instance.(result)).to eql(Success(:converted))
    end
  end
end
