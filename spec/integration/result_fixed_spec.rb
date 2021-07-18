# frozen_string_literal: true

# rubocop:disable Style/RescueModifier

require "English"
require "dry-types"

RSpec.describe(Dry::Monads::Result) do
  result = Dry::Monads::Result
  success = result::Success.method(:new)
  failure = result::Failure.method(:new)

  subject { Test::Operation.new }

  context "dry-types" do
    before do
      module Test
        module Types
          include Dry.Types()
        end
      end
    end

    context "errors as failures" do
      before do
        module Test
          class Operation
            Error =
              Types.Instance(ZeroDivisionError) |
              Types.Instance(NoMethodError)

            include Dry::Monads::Result(Error)
          end
        end
      end

      let(:division_error) { 1 / 0 rescue $ERROR_INFO }
      let(:no_method_error) { self.missing rescue $ERROR_INFO }
      let(:runtime_error) { "foo".upcase! rescue $ERROR_INFO }

      it "passes with known errors" do
        expect(subject.Failure(division_error)).to eql(failure.(division_error))
        expect(subject.Failure(no_method_error)).to eql(failure.(no_method_error))
      end

      it "raises an error on unexpected type" do
        expect { subject.Failure(runtime_error) }.to raise_error(Dry::Monads::InvalidFailureTypeError)
      end
    end
  end

  context "arbitrary objects" do
    before do
      module Test
        class Operation
          include Dry::Monads::Result(Symbol)
        end
      end
    end

    it "wraps symbols with failures" do
      expect(subject.Failure(:no_user)).to eql(failure.(:no_user))
    end

    it "tracks the caller" do
      error = subject.Failure(:no_user)
      expect(error.trace).to include("spec/integration/result_fixed_spec.rb")
    end

    it "raises an error on invalid type" do
      expect { subject.Failure("no_user") }
        .to raise_error(
          Dry::Monads::InvalidFailureTypeError,
          %q(Cannot create Failure from "no_user", it doesn't meet the constraints)
        )
    end

    it "uses unit as a default value" do
      expect(subject.Success()).to eql(success[Dry::Monads::Unit])
    end

    it "captures a block" do
      proc = proc { |x| x * 2 }
      expect(subject.Success(&proc)).to eql(success[proc])
    end
  end
end

# rubocop:enable Style/RescueModifier
