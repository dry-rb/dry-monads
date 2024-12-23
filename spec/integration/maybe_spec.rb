# frozen_string_literal: true

RSpec.describe(Dry::Monads::Maybe) do
  maybe = described_class

  include Dry::Monads::Maybe::Mixin

  let(:some) { Some(3) }
  let(:none) { None() }

  context "building values" do
    describe "#None" do
      subject { none }

      it { is_expected.to eql(maybe::None.new) }

      it "returns a new instance" do
        expect(none).to eql(None())
        expect(none.trace).to match(%r{spec/integration/maybe_spec.rb:9:in (`|')block})
      end
    end

    describe "#Some" do
      subject { some }

      it { is_expected.to eq maybe::Some.new(3) }
    end
  end

  context "bind some" do
    example "using named method with block" do
      expect(some.bind { _1 * 2 }).to eql(6)
    end

    example "using named method with lambda" do
      expect(some.bind(->(x) { x * 2 })).to eql(6)
    end
  end

  context "bind none" do
    example "using named method with block" do
      expect(none.bind { _1 * 2 }).to eql(None())
    end

    example "using named method with proc" do
      expect(none.bind(->(x) { x * 2 })).to eql(None())
    end
  end

  context "mapping" do
    context "some" do
      example "using block" do
        expect(some.fmap { _1 * 2 }).to eql(Some(6))
      end

      example "using proc" do
        expect(some.fmap(->(x) { x * 2 })).to eql(Some(6))
      end
    end

    context "none" do
      example "using block" do
        expect(none.fmap { _1 * 2 }).to eql(None())
      end

      example "using proc" do
        expect(none.fmap(->(x) { x * 2 })).to eql(None())
      end
    end
  end

  describe "chaining" do
    let(:inc) { :succ.to_proc }
    let(:maybe_inc) { ->(x) { Maybe(x.succ) } }

    context "going happy" do
      example "using lambda with lifting" do
        expect(some.fmap(inc).fmap(inc).fmap(inc).or(0)).to eql(Some(6))
      end

      example "using lambda without lifting" do
        expect(some.bind(&maybe_inc).bind { maybe_inc[_1] }.or(0)).to eql(Some(5))
      end

      example "using block" do
        result = some.bind { Some(inc[_1]) }.or(0)

        expect(result).to eql(Some(4))
      end
    end

    context "going unhappy path" do
      example "using values" do
        expect(none.fmap(inc).or(5)).to eql(5)
      end

      example "using values in a long chain" do
        expect(none.fmap(inc).or(Some(7).or(0))).to eql(Some(7))
      end

      example "using block" do
        expect(some.bind(->(_) { none }).fmap(inc).or { |_| 5 }).to eql(5)
      end
    end
  end

  context "applicative" do
    context "seq arguments" do
      let(:build_name) do
        Class.new do
          def call(first_name, last_name)
            "#{first_name} #{last_name}"
          end
        end
      end

      it "works" do
        expect(Some(build_name.new).apply(Some("John")).apply(Some("Doe"))).to eql(Some("John Doe"))
        expect(Some(build_name.new).apply(None()).apply(Some("Doe"))).to eql(None())
        expect(Some(build_name.new).apply(Some("John")).apply(None())).to eql(None())
      end
    end

    context "keywords" do
      let(:build_name) { -> (values) { "#{values.fetch(:first_name)} #{values.fetch(:last_name)}" } }

      it "works" do
        expect(Some(build_name).apply(Some(first_name: "John", last_name: "Doe"))).to eql(Some("John Doe"))
      end
    end

    context "mixed" do
      let(:build_name) { -> (first_name, rest) { "#{first_name} #{rest.fetch(:last_name)}" } }

      it "works" do
        expect(Some(build_name).apply(Some("John")).apply(Some(last_name: "Doe"))).to eql(Some("John Doe"))
      end
    end

    context "optional arguments" do
      let(:build_name) { -> (first_name, last_name = "Doe") { "#{first_name} #{last_name}" } }

      it "works" do
        expect(Some(build_name).apply(Some("John"))).to eql(Some("John Doe"))
      end

      it "raises an error on calling .ap on applied value" do
        expect {
          Some(build_name).apply(Some("John")).apply(Some("Doe"))
        }.to raise_error(TypeError, /Cannot apply/)
      end
    end
  end

  context ".to_proc" do
    let(:operation) do
      class Test::Operation
        include Dry::Monads::Maybe::Mixin

        def call(value)
          [
            value.map(&Maybe),
            value.map(&Some)
          ]
        end
      end

      Test::Operation.new
    end

    it "can be used for constants" do
      expect(operation.(["foo"])).to eql([[Some("foo")], [Some("foo")]])
    end
  end

  describe "matching" do
    let(:match) do
      lambda do |value|
        case value
        when Some("foo") then :foo_eql
        when Some(/\w+/) then :bar_rg
        when Some(42) then :int_match
        when Some(10..50) then :int_range
        when Some(-> x { x > 9000 }) then :int_proc_arg
        when Some { _1 > 100 } then :int_proc_block
        when None() then :none
        else
          :else
        end
      end
    end

    it "can be used in a case statement" do
      expect(match.(Some("foo"))).to eql(:foo_eql)
      expect(match.(Some("bar"))).to eql(:bar_rg)
      expect(match.(Some(42))).to eql(:int_match)
      expect(match.(Some(42.0))).to eql(:int_match)
      expect(match.(Some(12))).to eql(:int_range)
      expect(match.(Some(9123))).to eql(:int_proc_arg)
      expect(match.(Some(144))).to eql(:int_proc_block)
      expect(match.(None())).to eql(:none)
      expect(match.(Some(-1))).to eql(:else)
    end
  end
end
