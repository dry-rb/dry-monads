# frozen_string_literal: true

require_relative "../fixtures/rspec_ext_helper"

RSpec.describe "RSpec extension" do
  before(:all) do
    Dry::Monads.load_extensions(:rspec)
  end

  it "adds constructors and matchers" do
    expect(Success(1)).to be_success
    expect(Success(1)).to be_a_success
    expect(Success(1)).to be_success(1)
    expect(Success(1)).not_to be_success(2)
    expect(Success(1)).not_to be_a_success(2)
    expect(Failure(1)).to be_failure
    expect(Failure(1)).to be_a_failure
    expect(Failure(1)).to be_failure(1)
    expect(Failure(1)).not_to be_failure(2)
    expect(Failure(1)).not_to be_a_failure(2)
    expect(Some(1)).to be_some
    expect(Some(1)).to be_success
    expect(Some(1)).to be_some(1)
    expect(Some(1)).not_to be_some(2)
    expect(None()).to be_none
    expect(None()).not_to be_success
    expect(None()).to be_failure
    expect(None()).not_to be_some
    expect(None()).not_to be_some(1)
    expect(List[]).to be_empty
    expect(List[1, 2, 3]).not_to be_empty
  end

  context "clashing with rspec-expectations" do
    let(:operation) do
      Class.new {
        def success? = true
        def failure? = false
      }.new
    end

    it "works" do
      expect(operation).to be_success
      expect(operation).not_to be_failure
    end
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

      context "nested" do
        it "makes success" do
          expect(make_nested_success(1)).to be_success
        end
      end
    end
  end

  describe Dry::Monads::RSpec::Matchers, aggregate_failures: false do
    let(:operation) do
      module Test
        class Operation
          def success? = false
          def failure? = false
        end
      end

      Test::Operation.new
    end

    let(:operation_with_success) do
      module Test
        class OperationWithSuccess
          def success? = true
        end
      end

      Test::OperationWithSuccess.new
    end

    let(:unexpected_object) do
      module Test
        class Unexpected
        end
      end

      Test::Unexpected.new
    end

    context "error messages" do
      example "success" do
        expect {
          expect(Success(1)).to be_success(2)
        }.to raise_error("expected Success(1) to have value 2, but it was 1")

        expect {
          expect(1).to be_success
        }.to raise_error(
          "expected 1 to be one of the following values: Success, " \
          "Some, Value or respond to success?, but it's Integer"
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

        expect {
          expect(operation).to be_success
        }.to raise_error(
          "expected #{operation.inspect}.success? to return truthy value, " \
          "but it returned false or nil"
        )

        expect {
          expect(operation_with_success).not_to be_success
        }.to raise_error(
          "expected #{operation_with_success.inspect}.success? to return falsey value, " \
          "but it returned truthy value"
        )

        expect {
          expect(unexpected_object).to be_success
        }.to raise_error(
          "expected #{unexpected_object.inspect} to be one of the following values: " \
          "Success, Some, Value or respond to success?, but it's Test::Unexpected"
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
          "None, Error or respond to failure?, but it's Integer"
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
        }.to raise_error("expected 1 to be a Some value or respond to some?, but it's Integer")

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

module RSpecExtNamespace
  RSpec.describe "RSpec extension in a namespaced spec" do
    before(:all) do
      Dry::Monads.load_extensions(:rspec)
    end

    it "catches missing constants" do
      expect(Failure[:invalid]).to be_failure
      expect(Success[1]).to be_success([1])
      expect(Failure(1)).to be_a(Failure)
      expect(Some(1)).to be_a(Some)
      expect(None()).to be_a(None)
      expect(List[1]).to be_a(List)
    end
  end

  module Helper
    def build_failure = Failure[:from_helper]
  end

  RSpec.describe "RSpec extension with a helper module in a namespaced spec" do
    include Helper

    it "catches missing constants in the helper" do
      expect(build_failure).to be_failure(%i[from_helper])
    end
  end
end

RSpec.describe "RSpec extension loaded twice" do
  it "hooks constants only once and does not warn" do
    path = Gem.find_files("dry/monads/extensions/rspec.rb").first
    hook = Dry::Monads::RSpec::MissingConstants

    expect { load path }.not_to output.to_stderr
    expect(Object.singleton_class.ancestors.count(hook)).to be(1)
    expect(Dry::Monads::RSpec::MissingConstants).to be(hook)
  end
end

RSpec.describe "RSpec extension scope" do
  def hooked?(mod) = mod.singleton_class.ancestors.include?(Dry::Monads::RSpec::MissingConstants)

  it "does not hook modules that do not wrap a spec" do
    expect(hooked?(Module.new)).to be(false)
    expect(hooked?(Module.new { include Comparable })).to be(false)
  end
end

module RSpecExtOwnConstantNamespace
  class Failure; end

  RSpec.describe "RSpec extension in a namespace defining its own Failure" do
    it "prefers the namespace's constant" do
      expect(Failure).to equal(RSpecExtOwnConstantNamespace::Failure)
    end
  end
end

module RSpecExtFrozenNamespace
  RSpec.describe "RSpec extension in a frozen namespace" do
    it "catches missing constants" do
      expect(Failure[:invalid]).to be_failure
    end
  end

  freeze
end

module RSpecExtNonSpecNamespace
  require_relative "../fixtures/missing_constant"

  RSpec.describe "RSpec extension and application code" do
    def raise_exactly_name_error(pattern)
      raise_error do |error|
        expect(error.class).to be(NameError)
        expect(error.message).to match(pattern)
      end
    end

    it "does not catch constants referenced by application code" do
      expect { MissingConstant.new.(1) }.to raise_exactly_name_error(/Success/)
      expect { MissingConstant.new.lookup(:Success) }.to raise_exactly_name_error(/Success/)
    end

    it "does not catch unrelated missing constants" do
      expect { NoSuchConstant }.to raise_exactly_name_error(/NoSuchConstant/)
    end
  end
end
