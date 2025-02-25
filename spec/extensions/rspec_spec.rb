# frozen_string_literal: true

require_relative "../fixtures/rspec_ext_helper"

RSpec.describe "RSpec extension" do
  before(:all) do
    Dry::Monads.load_extensions(:rspec)
  end

  it "adds constructors and matchers" do
    expect(Success(1)).to be_success
    expect(Success(1)).to be_success(1)
    expect(Success(1)).not_to be_success(2)
    expect(Failure(1)).to be_failure
    expect(Failure(1)).to be_failure(1)
    expect(Failure(1)).not_to be_failure(2)
    expect(Some(1)).to be_some
    expect(Some(1)).to be_some(1)
    expect(Some(1)).not_to be_some(2)
    expect(None()).to be_none
    expect(None()).not_to be_some
    expect(None()).not_to be_some(1)
  end

  it "catches missing constants" do
    expect(Success(1)).to be_a(Success)
    expect(Failure(1)).to be_a(Failure)
    expect(Some(1)).to be_a(Some)
    expect(None()).to be_a(None)
  end

  context "patten matching" do
    example "with result" do
      success = Success(1)
      success => Success(value)
      expect(value).to eql(1)

      case Success(nested: Failure(:value))
      in Success(nested: Success(value))
        raise "unexpected"
      in Success(nested: Failure(value))
        expect(value).to eql(:value)
      end
    end

    example "with maybe" do
      maybe = Some(1)
      maybe => Some(value)
      expect(value).to eql(1)

      case Some(nested: None())
      in Some(nested: Some(value))
        raise "unexpected"
      in Some(nested: None())
        nil
      end
    end
  end

  context "with missing constant" do
    let(:operation) do
      require_relative "../fixtures/missing_constant"

      MissingConstant.new
    end

    it "raises an error when it comes from a non-spec file" do
      expect { operation.(1) }.to raise_error(NameError)
    end

    context "inline class" do
      let(:operation) do
        Class.new {
          def call(value)
            Success[value]
          end
        }.new
      end

      # we use debug_inspector to check if the error comes from a non-spec context
      it "raises an error when it comes from a non-spec context" do
        expect { operation.(1) }.to raise_error(NameError)
      end
    end

    context "helper" do
      include RSpecExtHelper

      it "makes success" do
        expect(make_success(1)).to be_success
        expect(make_success(1)).to be_success([1])
      end
    end
  end

  describe Dry::Monads::RSpec::Matchers, aggregate_failures: false do
    context "error messages" do
      example "success" do
        expect {
          expect(Success(1)).to be_success(2)
        }.to raise_error("expected Success(1) to have value 2, but it was 1")

        expect {
          expect(1).to be_success
        }.to raise_error(
          "expected 1 to be one of the following values: Success, " \
          "Some, Value, but it's Integer"
        )

        expect {
          expect(Success(1)).to be_success { |value| value.even? }
        }.to raise_error("expected Success(1) to have a value satisfying the given block")

        expect {
          expect(Success(1)).not_to be_success
        }.to raise_error(
          "expected Success(1) to not be one of the following values: Success, " \
          "Some, Value, but it is"
        )
      end

      example "failure" do
        expect {
          expect(Failure(1)).to be_failure(2)
        }.to raise_error("expected Failure(1) to have value 2, but it was 1")

        expect {
          expect(1).to be_failure
        }.to raise_error(
          "expected 1 to be one of the following values: Failure, " \
          "None, Error, but it's Integer"
        )

        expect {
          expect(Failure(1)).to be_failure { |value| value.even? }
        }.to raise_error("expected Failure(1) to have a value satisfying the given block")

        expect {
          expect(Failure(1)).not_to be_failure
        }.to raise_error(
          "expected Failure(1) to not be one of the following values: Failure, " \
          "None, Error, but it is"
        )
      end

      example "some" do
        expect {
          expect(Some(1)).to be_some(2)
        }.to raise_error("expected Some(1) to have value 2, but it was 1")

        expect {
          expect(1).to be_some
        }.to raise_error("expected 1 to be a Some value, but it's Integer")

        expect {
          expect(Some(1)).to be_some { |value| value.even? }
        }.to raise_error("expected Some(1) to have a value satisfying the given block")

        expect {
          expect(Some(1)).not_to be_some
        }.to raise_error("expected Some(1) to not be a Some value, but it is")
      end

      example "none" do
        expect {
          expect(Some()).to be_none
        }.to raise_error("expected Some() to be none")

        expect {
          expect(1).to be_none
        }.to raise_error("expected 1 to be none")
      end
    end
  end
end
