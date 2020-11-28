# frozen_string_literal: true

require "dry/monads/do"

RSpec.describe(Dry::Monads::Do) do
  result_mixin = Dry::Monads::Result::Mixin
  include result_mixin

  describe ".for" do
    let(:input_value) { 10 }
    let(:mixin) { Dry::Monads::Do.for(:answer, :square, :double) }
    let(:klass) do
      spec = self
      klass = Class.new do
        include spec.mixin

        def initialize(starting_value)
          @starting_value = starting_value
        end

        def answer
          c = yield(square) + yield(double)
          Success(c)
        end

        protected

        def square
          s = yield(starting_value) * yield(starting_value)
          Success(s)
        end

        private

        def double
          d = yield(starting_value) + yield(starting_value)
          Success(d)
        end

        attr_reader :starting_value
      end
      klass.include(result_mixin)
    end

    let(:equation) { klass.new(Success(input_value)) }

    it "can call a public method" do
      expect { equation.answer }.to_not raise_error
    end

    it "works" do
      expect(equation.answer).to eq(Success(120))
    end

    it "cannot call a protected method directly" do
      expect { equation.square }.to raise_error(NoMethodError, /protected method/)
    end

    it "cannot call a private method directly" do
      expect { equation.double }.to raise_error(NoMethodError, /private method/)
    end

    context "sharing mixin across classes" do
      let(:another_class) do
        spec = self

        Class.new do
          include spec.mixin

          private

          def initialize(starting_value)
            @starting_value = starting_value
          end

          def square
            s = yield(starting_value) * yield(starting_value)
            Success(s)
          end
        end
      end

      let(:another_equation) do
        another_class.new(Success(30))
      end

      it "keeps visibility separated" do
        expect { equation.square }.to raise_error(NoMethodError, /protected method/)
        expect { another_equation.square }.to raise_error(NoMethodError, /private method/)
      end
    end
  end
end
