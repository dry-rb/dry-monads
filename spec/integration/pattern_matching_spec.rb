# frozen_string_literal: true

RSpec.describe "pattern matching" do
  describe "Dry::Monads::Result" do
    include Dry::Monads[:result]

    context "Success" do
      it "matches on the singleton array of the value when value is not an array" do
        expect(
          (Success(1) in [1])
        ).to be(true)
      end

      it "matches on the value when value is an array" do
        expect(
          (Success([1]) in [1])
        ).to be(true)
      end

      it "matches on the empty array when value is Unit" do
        expect(
          (Success(Dry::Monads::Unit) in [])
        ).to be(true)
      end

      it "matches on the value's keys when value acts like a hash" do
        expect(
          (Success({code: 101, foo: :bar}) in { code: 101 })
        ).to be(true)
      end

      it "matches on the empty hash when value doesn't act like a hash" do
        expect(
          (Success(:foo) in {})
        ).to be(true)
      end
    end

    context "Failure" do
      it "matches on the singleton array of the value when value is not an array" do
        expect(
          (Failure(1) in [1])
        ).to be(true)
      end

      it "matches on the value when value is an array" do
        expect(
          (Failure([1]) in [1])
        ).to be(true)
      end

      it "matches on the empty array when value is Unit" do
        expect(
          (Failure(Dry::Monads::Unit) in [])
        ).to be(true)
      end

      it "matches on the value's keys when value acts like a hash" do
        expect(
          (Failure({code: 101, foo: :bar}) in { code: 101 })
        ).to be(true)
      end

      it "matches on the empty hash when value doesn't act like a hash" do
        expect(
          (Failure(:foo) in {})
        ).to be(true)
      end
    end
  end

  describe "Dry::Monads::Maybe" do
    include Dry::Monads[:maybe]

    context "Some" do
      it "matches on the singleton array of the value when value is not an array" do
        expect(
          (Some(1) in [1])
        ).to be(true)
      end

      it "matches on the value when value is an array" do
        expect(
          (Some([1]) in [1])
        ).to be(true)
      end

      it "matches on the empty array when value is Unit" do
        expect(
          (Some(Dry::Monads::Unit) in [])
        ).to be(true)
      end

      it "matches on the value's keys when value acts like a hash" do
        expect(
          (Some({code: 101, foo: :bar}) in { code: 101 })
        ).to be(true)
      end

      it "matches on the empty hash when value doesn't act like a hash" do
        expect(
          (Some(:foo) in {})
        ).to be(true)
      end
    end

    context "None" do
      it "matches on the empty array" do
        expect(
          (None() in [])
        ).to be(true)
      end

      it "matches on the empty hash" do
        expect(
          (None() in {})
        ).to be(true)
      end
    end
  end

  describe "Dry::Monads::List" do
    include Dry::Monads[:list, :result]

    it "matches on the value" do
      expect(
        (List([1]) in [1])
      ).to be(true)
    end
  end
end
