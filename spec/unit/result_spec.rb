# frozen_string_literal: true

RSpec.describe(Dry::Monads::Result) do
  result = described_class
  maybe = Dry::Monads::Maybe
  some = maybe::Some.method(:new)
  failure = result::Failure.method(:new)
  success = result::Success.method(:new)
  validated = Dry::Monads::Validated
  valid = validated::Valid.method(:new)
  invalid = validated::Invalid.method(:new)
  unit = Dry::Monads::Unit

  let(:upcase) { :upcase.to_proc }

  it_behaves_like "an applicative" do
    let(:pure) { success }
  end

  describe result::Success do
    subject { success["foo"] }

    it_behaves_like "a monad"

    let(:upcased_subject) { success["FOO"] }

    it { is_expected.to be_success }

    it { is_expected.not_to be_failure }

    it { is_expected.to eql(described_class.new("foo")) }
    it { is_expected.not_to eql(failure["foo"]) }

    it "dumps to string" do
      expect(subject.to_s).to eql('Success("foo")')
      expect(success[unit].to_s).to eql("Success()")
    end

    it "has custom inspection" do
      expect(subject.inspect).to eql('Success("foo")')
    end

    describe ".[]" do
      it "builds a Success with an array" do
        expect(described_class[:found, 1]).to eql(success[[:found, 1]])
      end
    end

    describe "#bind" do
      it "accepts a proc and does not lift the result" do
        expect(subject.bind(upcase)).to eql("FOO")
      end

      it "accepts a block too" do
        expect(subject.bind(&:upcase)).to eql("FOO")
      end

      it "passes extra arguments to a block" do
        expr_result = subject.bind(:foo) do |value, c|
          expect(value).to eql("foo")
          expect(c).to eql(:foo)
          true
        end

        expect(expr_result).to be true
      end

      it "passes extra arguments to a proc" do
        proc = lambda do |value, c|
          expect(value).to eql("foo")
          expect(c).to eql(:foo)
          true
        end

        expr_result = subject.bind(proc, :foo)

        expect(expr_result).to be true
      end
    end

    describe "#result" do
      subject do
        result::Success.new("Foo").result(
          ->(v) { v.downcase },
          ->(v) { v.upcase }
        )
      end

      it { is_expected.to eq("FOO") }
    end

    describe "#fmap" do
      it "accepts a proc and lifts the result to Result" do
        expect(subject.fmap(upcase)).to eql(upcased_subject)
      end

      it "accepts a block too" do
        expect(subject.fmap(&:upcase)).to eql(upcased_subject)
      end

      it "passes extra arguments to a block" do
        expr_result = subject.fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql("foo")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        expect(expr_result).to eql(result::Success.new(true))
      end

      it "passes extra arguments to a proc" do
        proc = lambda do |value, c1, c2|
          expect(value).to eql("foo")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        expr_result = subject.fmap(proc, :foo, :bar)

        expect(expr_result).to eql(result::Success.new(true))
      end
    end

    describe "#or" do
      it "accepts value as an alternative" do
        expect(subject.or("baz")).to be(subject)
      end

      it "accepts block as an alternative" do
        expect(subject.or { raise }).to be(subject)
      end

      it "ignores all values" do
        expect(subject.or(:foo, :bar, :baz) { raise }).to be(subject)
      end
    end

    describe "#or_fmap" do
      it "accepts value as an alternative" do
        expect(subject.or_fmap("baz")).to be(subject)
      end

      it "accepts block as an alternative" do
        expect(subject.or_fmap { raise }).to be(subject)
      end

      it "ignores all values" do
        expect(subject.or_fmap(:foo, :bar, :baz) { raise }).to be(subject)
      end
    end

    describe "#to_result" do
      subject { result::Success.new("foo").to_result }

      it "returns self" do
        is_expected.to eql(result::Success.new("foo"))
      end
    end

    describe "#to_maybe" do
      subject { result::Success.new("foo").to_maybe }

      it { is_expected.to be_an_instance_of maybe::Some }
      it { is_expected.to eql(some["foo"]) }

      context "value is nil" do
        around { |ex| suppress_warnings { ex.run } }
        subject { result::Success.new(nil).to_maybe }

        it { is_expected.to be_an_instance_of maybe::None }
        it { is_expected.to eql(maybe::None.new) }
      end
    end

    describe "#tee" do
      it "passes through itself when the block returns a Success" do
        expect(subject.tee(->(*) { result::Success.new("ignored") })).to eql(subject)
      end

      it "returns the block result when it is a Failure" do
        expect(subject.tee(->(*) { result::Failure.new("failure") }))
          .to be_an_instance_of result::Failure
      end
    end

    describe "#value_or" do
      it "returns existing value" do
        expect(subject.value_or("baz")).to eql(subject.value!)
      end

      it "ignores a block" do
        expect(subject.value_or { "baz" }).to eql(subject.value!)
      end
    end

    describe "#to_validated" do
      it "returns Valid" do
        expect(subject.to_validated).to eql(valid.("foo"))
      end
    end

    context "keyword values" do
      subject { result::Success.new(foo: "foo") }
      let(:struct) { Class.new(Hash)[bar: "foo"] }

      describe "#bind" do
        it "passed extra keywords to block along with value" do
          expr_result = subject.bind(bar: "bar") do |values|
            expect(values.fetch(:foo)).to eql("foo")
            expect(values.fetch(:bar)).to eql("bar")
            true
          end

          expect(expr_result).to be true
        end

        it "doesn't use destructuring if it's not needed" do
          expect(success.(struct).bind { |x| x }.class).to be(struct.class)
          expect(success.(struct).bind(nil, bar: 1) { |x| x }.class).to be(struct.class)
        end
      end
    end

    context "mixed values" do
      subject { result::Success.new(foo: "foo", "bar" => "bar") }

      describe "#bind" do
        it "passed extra keywords to block along with value" do
          expr_result = subject.bind(:baz, quux: "quux") do |value, baz, rest|
            expect(value).to eql(subject.value!)
            expect(baz).to eql(:baz)
            expect(rest.fetch(:quux)).to eql("quux")
            true
          end

          expect(expr_result).to be true
        end
      end
    end

    describe "#flip" do
      it "transforms Success to Failure" do
        expect(subject.flip).to eql(failure["foo"])
      end

      it "tracks the caller" do
        expect(subject.flip.trace).to include("spec/unit/result_spec.rb")
      end
    end

    describe "#apply" do
      subject { success[:upcase.to_proc] }

      it "applies a wrapped function" do
        expect(subject.apply(success["foo"])).to eql(success["FOO"])
        expect(subject.apply(failure["foo"])).to eql(failure["foo"])
      end
    end

    describe "#value!" do
      it "unwraps the value" do
        expect(subject.value!).to eql("foo")
      end
    end

    # rubocop:disable Style/CaseEquality
    describe "#===" do
      it "matches on the wrapped value" do
        expect(success["foo"]).to be === success["foo"]
        expect(success[/\w+/]).to be === success["foo"]
        expect(success[:bar]).not_to be === success["foo"]
        expect(success[10..50]).to be === success[42]
      end
    end
    # rubocop:enable Style/CaseEquality

    describe "#discard" do
      it "nullifies the value" do
        expect(success["foo"].discard).to eql(success[unit])
      end
    end

    describe "#flatten" do
      it "removes one level of monad" do
        expect(success[success["foo"]].flatten).to eql(success["foo"])
      end

      it "returns Failure for Success(Failure(_))" do
        expect(success[failure["foo"]].flatten).to eql(failure["foo"])
      end
    end

    describe "#and" do
      it "joins two success values with a block" do
        expect(success["foo"].and(success["bar"]) { |foo, bar| [foo, bar] })
          .to eql(success[%w[foo bar]])
      end

      it "returns failure if argument is failure" do
        expect(success["foo"].and(failure[123]) { |_foo, _bar| raise }).to eql(failure[123])
      end

      it "returns a tuple if no block given" do
        expect(success["foo"].and(success["bar"])).to eql(success[%w[foo bar]])
        expect(some["foo"].and(failure[123])).to eql(failure[123])
      end
    end

    describe "#either" do
      it "returns first function applied to the value" do
        expect(success["foo"].either(-> x { "#{x}foo" }, -> x { "#{x}bar" })).to eq("foofoo")
      end
    end

    describe "#alt_map" do
      it "is a no-op" do
        expect(success.("foo").alt_map { raise }).to eql(
          success.("foo")
        )
        expect(success.("foo").alt_map(proc { raise })).to eql(
          success.("foo")
        )
      end
    end
  end

  describe result::Failure do
    subject { result::Failure.new("bar") }

    describe ".call" do
      it "is an alias for new" do
        expect(result::Failure.("bar")).to eql(subject)
        expect((-> x { x.downcase } >> result::Failure).("BAR")).to eql(subject)
      end
    end

    it_behaves_like "a monad"

    it { is_expected.not_to be_success }

    it { is_expected.to be_failure }

    it { is_expected.to eql(described_class.new("bar")) }
    it { is_expected.not_to eql(result::Success.new("bar")) }

    it "dumps to string" do
      expect(subject.to_s).to eql('Failure("bar")')
      expect(failure[unit].to_s).to eql("Failure()")
    end

    it "has custom inspection" do
      expect(subject.inspect).to eql('Failure("bar")')
    end

    describe ".[]" do
      it "builds a Failure with an array" do
        expect(described_class[:not_found, :but_tried]).to eql(failure[[:not_found, :but_tried]])
      end
    end

    describe "#bind" do
      it "accepts a proc and returns itself" do
        expect(subject.bind(upcase)).to be subject
      end

      it "accepts a block and returns itself" do
        expect(subject.bind(&:upcase)).to be subject
      end

      it "ignores extra arguments" do
        expect(subject.bind(1, 2, 3) { raise }).to be subject
      end
    end

    describe "#result" do
      subject do
        result::Failure.new("Foo").result(
          ->(v) { v.downcase },
          ->(v) { v.upcase }
        )
      end

      it { is_expected.to eq("foo") }
    end

    describe "#fmap" do
      it "accepts a proc and returns itself" do
        expect(subject.fmap(upcase)).to be subject
      end

      it "accepts a block and returns itself" do
        expect(subject.fmap(&:upcase)).to be subject
      end

      it "ignores arguments" do
        expect(subject.fmap(1, 2, 3) { raise }).to be subject
      end
    end

    describe "#or" do
      it "accepts a value as an alternative" do
        expect(subject.or("baz")).to eql("baz")
      end

      it "accepts a block as an alternative" do
        expect(subject.or { "baz" }).to eql("baz")
      end

      it "passes extra arguments to a block" do
        expr_result = subject.or(:foo, :bar) do |value, c1, c2|
          expect(value).to eql("bar")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          "baz"
        end

        expect(expr_result).to eql("baz")
      end
    end

    describe "#or_fmap" do
      it "maps an alternative" do
        expect(subject.or_fmap("baz")).to eql(success["baz"])
      end

      it "accepts a block" do
        expect(subject.or_fmap { "baz" }).to eql(success["baz"])
      end

      it "passes extra arguments to a block" do
        expr_result = subject.or_fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql("bar")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          "baz"
        end

        expect(expr_result).to eql(success["baz"])
      end
    end

    describe "#to_result" do
      let(:subject) { result::Failure.new("bar").to_result }

      it "returns self" do
        is_expected.to eql(result::Failure.new("bar"))
      end
    end

    describe "#to_maybe" do
      let(:subject) { result::Failure.new("bar").to_maybe }

      it { is_expected.to be_an_instance_of maybe::None }
      it { is_expected.to eql(maybe::None.new) }

      it "tracks the caller" do
        expect(subject.to_maybe.trace).to include("spec/unit/result_spec.rb")
      end
    end

    describe "#tee" do
      it "accepts a proc and returns itself" do
        expect(subject.tee(upcase)).to be subject
      end

      it "accepts a block and returns itself" do
        expect(subject.tee(&:upcase)).to be subject
      end

      it "ignores arguments" do
        expect(subject.tee(1, 2, 3) { raise }).to be subject
      end
    end

    describe "#flip" do
      it "transforms Failure to Success" do
        expect(subject.flip).to eql(success["bar"])
      end
    end

    describe "#value_or" do
      it "returns passed value" do
        expect(subject.value_or("baz")).to eql("baz")
      end

      it "executes a block" do
        expect(subject.value_or { |bar| "foo#{bar}" }).to eql("foobar")
      end
    end

    describe "#apply" do
      it "does nothing" do
        expect(subject.apply(success["foo"])).to be(subject)
        expect(subject.apply(failure["foo"])).to be(subject)
      end
    end

    describe "#value!" do
      it "raises an error" do
        expect { subject.value! }.to(raise_error { |error|
          expect(error).to be_a Dry::Monads::UnwrapError
          expect(error.message).to match 'value! was called on Failure("bar")'
          expect(error.receiver).to eq subject
        })
      end
    end

    # rubocop:disable Style/CaseEquality
    describe "#===" do
      it "matches using the error value" do
        expect(failure["bar"]).to be === subject
        expect(failure[/\w+/]).to be === subject
        expect(failure[String]).to be === subject
        expect(failure["foo"]).not_to be === subject
      end
    end
    # rubocop:enable Style/CaseEquality

    describe "#to_validated" do
      it "returns Invalid" do
        expect(subject.to_validated).to eql(invalid.("bar"))
      end
    end

    describe "#discard" do
      it "returns self back" do
        m = failure[1]
        expect(m.discard).to be m
      end
    end

    describe "#flatten" do
      it "always return itself" do
        expect(failure["foo"].flatten).to eql(failure["foo"])
      end
    end

    describe "#and" do
      it "always return itself" do
        expect(failure[123].and(success["foo"]) { raise }).to eql(failure[123])
        expect(failure[123].and(success["foo"])).to eql(failure[123])
        expect(failure[123].and(failure["foo"])).to eql(failure[123])
      end
    end

    describe "#either" do
      it "returns second function applied to the value" do
        expect(failure["bar"].either(-> x { "#{x}foo" }, -> x { "#{x}bar" })).to eq("barbar")
      end
    end
  end

  describe result::Mixin do
    subject(:context) { Object.new.tap { |o| o.extend(result::Mixin) } }

    describe "#Success" do
      example "with plain value" do
        expect(subject.Success("something")).to eql(success["something"])
      end

      example "with a block" do
        block = -> { "something" }
        expect(subject.Success(&block)).to eql(success[block])
      end

      it "returns Unit when no value given" do
        expect(subject.Success()).to eql(success[unit])
      end
    end

    describe "#Failure" do
      example "with plain value" do
        expect(subject.Failure("something else")).to eql(failure["something else"])
      end

      example "with a block" do
        block = -> { "something" }
        expect(subject.Failure(&block)).to eql(failure[block])
      end

      it "raises an ArgumentError on missing value" do
        expect(subject.Failure()).to eql(failure[unit])
      end

      it "tracks the caller" do
        expect(subject.Failure("fail").trace).to include("spec/unit/result_spec.rb")
      end
    end

    describe "#alt_map" do
      it "map over the failure value" do
        expect(failure.("foo").alt_map(&:upcase)).to eql(
          failure.("FOO")
        )
        expect(subject.Failure("foo").alt_map(:upcase.to_proc)).to eql(
          failure.("FOO")
        )
      end
    end
  end
end
