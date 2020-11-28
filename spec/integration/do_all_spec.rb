# frozen_string_literal: true

require "dry/monads/result"
require "dry/monads/do/all"

RSpec.describe(Dry::Monads::Do::All) do
  result_mixin = Dry::Monads::Result::Mixin
  include result_mixin

  before { stub_const("VisibilityLeak", Class.new(StandardError)) }

  shared_examples_for "Do::All" do
    context "include first" do
      let(:adder) do
        spec = self
        Class.new {
          include spec.mixin, result_mixin

          def sum(a, b)
            c = yield(a) + yield(b)
            Success(c)
          end
        }.new
      end

      it "wraps arbitrary methods defined _after_ mixing in" do
        expect(adder.sum(Success(1), Success(2))).to eql(Success(3))
        expect(adder.sum(Success(1), Failure(2))).to eql(Failure(2))
        expect(adder.sum(Failure(1), Success(2))).to eql(Failure(1))
      end

      it "removes uses a given block" do
        expect(adder.sum(1, 2) { |x| x }).to eql(Success(3))
      end
    end

    context "visibility protection" do
      let(:object) do
        spec = self
        Class.new {
          include spec.mixin, result_mixin

          protected

          def my_protected_method
            raise VisibilityLeak, "Should not be able to call a protected method"
          end

          private

          def my_private_method
            raise VisibilityLeak, "Should not be able to call a private method"
          end
        }.new
      end

      it "is preserved for protected methods" do
        expect { object.my_protected_method }.to raise_error(NoMethodError)
      end

      it "is preserved for private methods" do
        expect { object.my_private_method }.to raise_error(NoMethodError)
      end
    end
  end

  context "Do::All" do
    let(:mixin) { Dry::Monads::Do::All }

    it_behaves_like "Do::All"

    it "wraps already defined method" do
      klass = Class.new do
        def sum(a, b)
          c = yield(a) + yield(b)
          Success(c)
        end
      end

      klass.include(mixin, result_mixin)
      adder = klass.new

      expect(adder.sum(Success(1), Success(2))).to eql(Success(3))
    end

    it "preserves private methods" do
      klass = Class.new do
        private

        def my_private_method
          raise VisibilityLeak, "Should not be able to call a private method"
        end
      end
      klass.include(mixin, result_mixin)
      object = klass.new

      expect { object.my_private_method }.to raise_error(NoMethodError)
    end

    it "preserves protected methods" do
      klass = Class.new do
        protected

        def my_protected_method
          raise VisibilityLeak, "Should not be able to call a protected method"
        end
      end
      klass.include(mixin, result_mixin)
      object = klass.new

      expect { object.my_protected_method }.to raise_error(NoMethodError)
    end

    context "inheritance" do
      it "works with inheritance" do
        base = Class.new.include(mixin, result_mixin)
        child = Class.new(base) {
          def call
            result = yield Success(:success)
            Success(result.to_s)
          end
        }

        expect(child.new.call).to eql(Success("success"))
      end

      it "doesn't care about the order" do
        base = Class.new.include(mixin, result_mixin)
        child = Class.new(base)
        base.class_eval do
          def call
            result = yield Success(:success)
            Success(result.to_s)
          end
        end

        expect(base.new.call).to eql(Success("success"))
        expect(child.new.call).to eql(Success("success"))
      end

      it "preserves private methods" do
        base = Class.new.include(mixin, result_mixin)
        klass = Class.new(base) do
          private

          def my_private_method
            raise VisibilityLeak, "Should not be able to call a private method"
          end
        end

        klass.include(mixin, result_mixin)
        object = klass.new

        expect { object.my_private_method }.to raise_error(NoMethodError)
      end

      it "preserves protected methods" do
        base = Class.new.include(mixin, result_mixin)
        klass = Class.new(base) do
          protected

          def my_protected_method
            raise VisibilityLeak, "Should not be able to call a protected method"
          end
        end

        klass.include(mixin, result_mixin)
        object = klass.new

        expect { object.my_protected_method }.to raise_error(NoMethodError)
      end
    end

    context "class level" do
      context "mixin then def" do
        let(:klass) do
          Class.new do
            extend result_mixin
            extend Dry::Monads::Do::All

            def self.call
              result = yield Success(:success)

              Success(result.to_s)
            end
          end
        end

        it "works" do
          expect(klass.()).to eql(Success("success"))
        end
      end

      context "def then mixin" do
        let(:klass) do
          Class.new do
            extend result_mixin

            def self.call
              result = yield Success(:success)

              Success(result.to_s)
            end

            extend Dry::Monads::Do::All
          end
        end

        it "works" do
          expect(klass.()).to eql(Success("success"))
        end
      end

      context "generated mixin" do
        let(:klass) do
          Class.new do
            extend result_mixin
            extend Dry::Monads[:do]

            def self.call
              result = yield Success(:success)

              Success(result.to_s)
            end
          end
        end

        it "works" do
          expect(klass.()).to eql(Success("success"))
        end
      end
    end
  end

  context "Do" do
    let(:mixin) { Dry::Monads::Do }

    it_behaves_like "Do::All"
  end
end
