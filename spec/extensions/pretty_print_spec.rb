# frozen_string_literal: true

require "pp"

RSpec.describe "pretty print" do
  maybe = Dry::Monads::Maybe
  result = Dry::Monads::Result
  try = Dry::Monads::Try

  some = maybe::Some.method(:new)
  none = maybe::None.new
  success = result::Success.method(:new)
  failure = result::Failure.method(:new)

  unit = Dry::Monads::Unit

  def pretty_print(value)
    out = +""
    PP.pp(value, out)
    out
  end

  describe "Maybe" do
    describe "Some" do
      specify "non-unit" do
        expect(pretty_print(some["foo"])).to eql(%{Some("foo")\n})
      end

      specify "unit" do
        expect(pretty_print(some[unit])).to eql("Some()\n")
      end

      specify "array" do
        expect(pretty_print(some[%w[foo bar]])).to eql(%{Some(["foo", "bar"])\n})
      end

      specify "long array" do
        expect(pretty_print(some[["foo"] * 30])).to eql(
          %{Some(\n ["foo",\n#{(['  "foo"'] * 29).join(",\n")}])\n}
        )
      end
    end

    describe "None" do
      specify "non-unit" do
        expect(pretty_print(none)).to eql("None\n")
      end
    end
  end

  describe "Result" do
    describe "Success" do
      specify "non-unit" do
        expect(pretty_print(success["foo"])).to eql(%{Success("foo")\n})
      end

      specify "unit" do
        expect(pretty_print(success[unit])).to eql("Success()\n")
      end
    end

    describe "Failure" do
      specify "non-unit" do
        expect(pretty_print(failure["foo"])).to eql(%{Failure("foo")\n})
      end

      specify "unit" do
        expect(pretty_print(failure[unit])).to eql("Failure()\n")
      end
    end
  end

  describe "Try" do
    error = ZeroDivisionError

    describe "Value" do
      specify "non-unit" do
        expect(pretty_print(try[error, &-> { "foo" }])).to eql(%{Value("foo")\n})
      end

      specify "unit" do
        expect(pretty_print(try[error, &-> { unit }])).to eql("Value()\n")
      end
    end

    describe "Error" do
      specify "non-unit" do
        expect(pretty_print(try[error, &-> { 1 / 0 }])).to eql(%{Error(#<ZeroDivisionError: divided by 0>)\n})
      end
    end
  end

  describe "List" do
    list = Dry::Monads::List

    specify "non-unit" do
      expect(pretty_print(list[1, 2, 3])).to eql(%{List([1, 2, 3])\n})
    end
  end

  describe "Task" do
    def task(&block)
      Dry::Monads::Task.new(&block)
    end

    specify "not terminated" do
      expect(pretty_print(task { sleep 0.1; 2 })).to eql(%{Task(?)\n})
    end

    specify "fulfilled" do
      task = task { 2 }
      task.value!
      expect(pretty_print(task)).to eql(%{Task(value=2)\n})
    end

    specify "fulfilled with unit" do
      task = task { unit }
      task.value!
      expect(pretty_print(task)).to eql(%{Task(value=())\n})
    end

    specify "rejected" do
      task = task { 1 / 0 }
      begin
        task.value!
      rescue StandardError
        nil
      end
      expect(pretty_print(task)).to eql(%{Task(error=#<ZeroDivisionError: divided by 0>)\n})
    end

    specify "long array" do
      task = task { ["foo"] * 30 }
      task.value!
      expect(pretty_print(task)).to eql(%{Task(value=\n ["foo",\n#{(['  "foo"'] * 29).join(",\n")}])\n})
    end
  end

  describe "Validated" do
    validated = Dry::Monads::Validated

    valid = validated::Valid.method(:new)
    invalid = validated::Invalid.method(:new)

    describe "Valid" do
      specify "non-unit" do
        expect(pretty_print(valid[1])).to eql(%{Valid(1)\n})
      end

      specify "unit" do
        expect(pretty_print(valid[unit])).to eql("Valid()\n")
      end
    end

    describe "Invalid" do
      specify "non-unit" do
        expect(pretty_print(invalid["foo"])).to eql(%{Invalid("foo")\n})
      end

      specify "unit" do
        expect(pretty_print(invalid[unit])).to eql("Invalid()\n")
      end
    end
  end

  describe "Lazy" do
    def lazy(&block)
      Dry::Monads::Lazy.new(&block)
    end

    specify "not evaluated" do
      expect(pretty_print(lazy { sleep 0.1; 1 })).to eql(%{Lazy(?)\n})
    end

    specify "evaluated" do
      expect(pretty_print(lazy { 1 }.force)).to eql(%{Lazy(1)\n})
    end

    specify "evaluated with unit" do
      expect(pretty_print(lazy { unit }.force)).to eql(%{Lazy()\n})
    end

    specify "evaluated with error" do
      expect(pretty_print(lazy { 1 / 0 }.force)).to eql(%{Lazy(error=#<ZeroDivisionError: divided by 0>)\n})
    end
  end
end
