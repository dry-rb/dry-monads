# frozen_string_literal: true

require "dry/monads/do"

RSpec.describe(Dry::Monads::Do) do
  result_mixin = Dry::Monads::Result::Mixin
  include result_mixin

  describe ".for" do
    let(:input_value) { 10 }
    let(:equation) do
      klass = Class.new do
        include Dry::Monads::Do.for(:answer, protected: [:square], private: [:double])

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
      klass.tap { |c| c.include(result_mixin) }.new(Success(input_value))
    end

    it "can call a public method" do
      expect { equation.answer }.to_not raise_error
    end

    it "works" do
      expect(equation.answer).to eq(Success(120))
    end

    it "cannot call a protected method directly" do
      expect { equation.square }.to raise_error(NoMethodError)
    end

    it "cannot call a private method directly" do
      expect { equation.double }.to raise_error(NoMethodError)
    end
  end
end
