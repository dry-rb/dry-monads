# frozen_string_literal: true

RSpec.describe(Dry::Monads::Result) do
  include Dry::Monads::Result::Mixin

  describe "matching" do
    include Dry::Monads::Maybe::Mixin

    let(:match) do
      lambda do |value|
        case value
        when Success("foo") then :foo_eql
        when Success(/\w+/) then :bar_rg
        when Success(42) then :int_match
        when Success(10..50) then :int_range
        when Success(-> x { x > 9000 }) then :int_proc_arg
        when Success { |x| x > 100 } then :int_proc_block
        when Failure(10) then :ten_eql
        when Failure(/\w+/) then :failure_rg
        when Failure { _1 > 90 } then :failure_block
        else
          :else
        end
      end
    end

    it "can be used in a case statement" do
      expect(match.(Success("foo"))).to eql(:foo_eql)
      expect(match.(Success("bar"))).to eql(:bar_rg)
      expect(match.(Success(42))).to eql(:int_match)
      expect(match.(Success(42.0))).to eql(:int_match)
      expect(match.(Success(12))).to eql(:int_range)
      expect(match.(Success(9123))).to eql(:int_proc_arg)
      expect(match.(Success(144))).to eql(:int_proc_block)
      expect(match.(Failure(10))).to eql(:ten_eql)
      expect(match.(Failure("foo"))).to eql(:failure_rg)
      expect(match.(Failure(100))).to eql(:failure_block)
      expect(match.(Success(-1))).to eql(:else)
    end

    # rubocop:disable Style/CaseEquality
    it "works with nested values" do
      expect(Success(Some(Integer))).to be === Success(Some(5))
      expect(Success(Some(Integer))).not_to be === Success(None())
    end
    # rubocop:enable Style/CaseEquality
  end

  context ".to_proc" do
    let(:operation) do
      class Test::Operation
        include Dry::Monads::Success::Mixin

        def call(value)
          [
            value.map(&Success),
            value.map(&Failure)
          ]
        end
      end

      Test::Operation.new
    end

    it "can be used for constants" do
      expect(operation.(["foo"])).to eql([[Success("foo")], [Failure("foo")]])
    end
  end
end
