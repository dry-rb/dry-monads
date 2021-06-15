# frozen_string_literal: true

RSpec.describe(Dry::Monads::Do) do
  include Dry::Monads::Maybe::Mixin
  include Dry::Monads::Result::Mixin
  include Dry::Monads::Try::Mixin
  include Dry::Monads::List::Mixin
  include Dry::Monads::Validated::Mixin

  before do
    module Test
      class Operation
        include Dry::Monads::Do.for(:call)
        include Dry::Monads::Maybe::Mixin
        include Dry::Monads::Result::Mixin
        include Dry::Monads::Try::Mixin
        include Dry::Monads::List::Mixin
        include Dry::Monads::Validated::Mixin
      end
    end
  end

  let(:klass) { Test::Operation }

  let(:instance) { klass.new }

  context "with Result" do
    context "successful case" do
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

      it "returns the result of a statement" do
        expect(instance.call).to eql(Success(3))
      end
    end

    context "first failure" do
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

      it "returns failure" do
        expect(instance.call).to eql(Failure(:no_one))
      end
    end

    context "second failure" do
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

      it "returns failure" do
        expect(instance.call).to eql(Failure(:no_two))
      end
    end

    context "with stateful blocks" do
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
          rescue StandardError => e
            @rolled_back = true
            raise e
          end
        end
      end

      it "halts the executing with an exception" do
        expect(instance.call).to eql(Failure(:no_two))
        expect(instance.rolled_back).to be(true)
      end
    end
  end

  context "with Maybe" do
    context "successful case" do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns the result of a statement" do
        expect(instance.call).to eql(Some(3))
      end
    end

    context "first failure" do
      before do
        klass.class_eval do
          def call
            m1 = None()
            m2 = Some(2)

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns none" do
        expect(instance.call).to be_none
      end
    end

    context "second failure" do
      before do
        klass.class_eval do
          def call
            m1 = Some(1)
            m2 = None()

            Some(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns none" do
        expect(instance.call).to be_none
      end
    end
  end

  context "with Try" do
    context "successful case" do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 }

            Dry::Monads::Try.pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns the result of a statement" do
        expect(instance.call).to eql(Dry::Monads::Try.pure(3))
      end
    end

    context "first failure" do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 / 0 }
            m2 = Try { 2 }

            Dry::Monads::Try.pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns Error" do
        expect(instance.call).to be_error
      end
    end

    context "second failure" do
      before do
        klass.class_eval do
          def call
            m1 = Try { 1 }
            m2 = Try { 2 / 0 }

            Dry::Monads::Try.pure(yield(m1, m2).reduce(:+))
          end
        end
      end

      it "returns Error" do
        expect(instance.call).to be_error
      end
    end
  end

  context "yielding multiple arguments" do
    context "success" do
      before do
        klass.class_eval do
          def call
            result = yield Success(1), Success(2)

            Success(result)
          end
        end
      end

      it "casts the given parameters to an array and traverses it" do
        expect(instance.call).to eql(Success([1, 2]))
      end
    end

    context "failure" do
      before do
        klass.class_eval do
          def call
            result = yield Success(0), Failure(1), Failure(2)

            Success(result)
          end
        end
      end

      it "returns the first failure case" do
        expect(instance.call).to eql(Failure(1))
      end
    end
  end

  context "yielding arrays" do
    context "success" do
      before do
        klass.class_eval do
          def call
            result = yield [Success(1), Success(2)]

            Success(result)
          end
        end
      end

      it "casts the given array to a list, infers the monad instance and traverses the list" do
        expect(instance.call).to eql(Success(List([1, 2])))
      end
    end

    context "failure" do
      before do
        klass.class_eval do
          def call
            result = yield [Success(0), Failure(1), Failure(2)]

            Success(result)
          end
        end
      end

      it "returns the first failure case" do
        expect(instance.call).to eql(Failure(1))
      end
    end
  end

  context "passing procs" do
    before do
      class Test::Operation
        def call
          result = yield Success(:heya)

          Success(result)
        end
      end
    end

    it "just calls the passed block, ignoring the do notation" do
      expect(
        instance.call { Failure(:foo) }
      ).to eql(Success(Failure(:foo)))
    end
  end

  context "yielding lists" do
    context "success" do
      before do
        class Test::Operation
          def call
            result = yield List::Result[Success(1), Success(2)]

            Success(result)
          end
        end
      end

      it "casts the given array to a list, infers the monad instance and traverses the list" do
        expect(instance.call).to eql(Success(List([1, 2])))
      end
    end

    context "failure" do
      before do
        class Test::Operation
          def call
            result = yield List::Result[Success(0), Failure(1), Failure(2)]

            Success(result)
          end
        end
      end

      it "returns the first failure case" do
        expect(instance.call).to eql(Failure(1))
      end
    end
  end

  context "implicit conversions" do
    before do
      class Test::ValidationResult
        def initialize(success)
          @success = success
        end

        def to_monad
          if @success
            Dry::Monads::Success(:converted)
          else
            Dry::Monads::Failure(:converted)
          end
        end
      end

      class Test::Operation
        def call(obj)
          result = yield(obj)

          Success(result)
        end
      end
    end

    it "implicitly converts an arbitrary object to a monad" do
      success = Test::ValidationResult.new(true)
      expect(instance.(success)).to eql(Success(:converted))

      failure = Test::ValidationResult.new(false)
      expect(instance.(failure)).to eql(Failure(:converted))
    end
  end

  context "with validated" do
    context "with successes" do
      before do
        class Test::Operation
          def call
            result = yield List::Validated[
                             Valid(1),
                             Valid(2),
                             Valid(3)
                           ]

            Success(result)
          end
        end
      end

      it "returns a concatenated list of results" do
        expect(instance.call).to eql(Success(List([1, 2, 3])))
      end
    end

    context "with failures" do
      before do
        class Test::Operation
          def call
            result = yield List::Validated[
                             Valid(1),
                             Invalid(2),
                             Invalid(3)
                           ]

            Success(result)
          end
        end
      end

      it "returns a concatenated list of failures" do
        expect(instance.call).to eql(Invalid(List([2, 3])))
      end
    end
  end

  describe "Do::Mixin" do
    context "with a proc" do
      include Dry::Monads::Do::Mixin

      let(:block) do
        lambda do |success|
          self.() do
            value_1 = bind(Success(2))
            value_2 = bind(success ? Success(3) : Failure("oops"))
            Success(value_1 + value_2)
          end
        end
      end

      context "successful case" do
        it "returns the result of a statement" do
          expect(block.(true)).to eql(Success(5))
        end
      end

      context "first failure" do
        it "returns failure" do
          expect(block.(false)).to eql(Failure("oops"))
        end
      end
    end

    context "with a class" do
      before do
        klass.class_eval do
          include Dry::Monads::Do::Mixin

          def call(success)
            first_value = bind Success(2)
            second_value = bind success ? Success(3) : Failure("oops")
            Success(first_value + second_value)
          end
        end
      end

      context "successful case" do
        it "returns the result of a statement" do
          expect(instance.(true)).to eql(Success(5))
        end
      end

      context "failed case" do
        it "returns the result of a statement" do
          expect(instance.(false)).to eql(Failure("oops"))
        end
      end
    end
  end
end
