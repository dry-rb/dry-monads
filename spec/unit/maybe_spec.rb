# frozen_string_literal: true

RSpec.describe(Dry::Monads::Maybe) do
  maybe = described_class
  some = maybe::Some.method(:new)
  none = maybe::None.new
  result = Dry::Monads::Result
  success = result::Success.method(:new)
  failure = result::Failure.method(:new)
  unit = Dry::Monads::Unit

  let(:upcase) { :upcase.to_proc }

  it_behaves_like "an applicative" do
    let(:pure) { some }
  end

  describe maybe do
    describe ".to_proc" do
      it "returns a block for coerce" do
        expect(maybe.to_proc.("foo")).to eql(some["foo"])
        expect(maybe.to_proc.(nil)).to eql(none)
      end
    end
  end

  describe maybe::Some do
    subject { described_class.new("foo") }

    it_behaves_like "a monad"

    let(:upcased_subject) { described_class.new("FOO") }

    it { is_expected.to be_some }
    it { is_expected.not_to be_none }

    it { is_expected.to eql(described_class.new("foo")) }
    it { is_expected.not_to eql(none) }

    it "dumps to string" do
      expect(subject.to_s).to eql('Some("foo")')
      expect(some[unit].to_s).to eql("Some()")
    end

    it "has custom inspection" do
      expect(subject.inspect).to eql('Some("foo")')
    end

    describe ".to_proc" do
      it "returns a constructor block" do
        expect(maybe::Some.to_proc.("foo")).to eql(subject)
      end
    end

    describe ".call" do
      it "is an alias for new" do
        expect(maybe::Some.("foo")).to eql(subject)

        if RUBY_VERSION > "2.6"
          expect((-> x { x.downcase } >> maybe::Some).("FOO")).to eql(subject)
        end
      end
    end

    describe ".[]" do
      it "builds a Some with an array" do
        expect(described_class[1, 2]).to eql(some[[1, 2]])
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
        result = subject.bind(:foo) do |value, c|
          expect(value).to eql("foo")
          expect(c).to eql(:foo)
          true
        end

        expect(result).to be true
      end

      it "passes extra arguments to a proc" do
        proc = lambda do |value, c|
          expect(value).to eql("foo")
          expect(c).to eql(:foo)
          true
        end

        result = subject.bind(proc, :foo)

        expect(result).to be true
      end
    end

    describe "#value!" do
      it "unwraps the value" do
        expect(subject.value!).to eql("foo")
      end
    end

    describe "#fmap" do
      it "accepts a proc and does not lift the result to maybe" do
        expect(subject.fmap(upcase)).to eql(upcased_subject)
      end

      it "accepts a block too" do
        expect(subject.fmap(&:upcase)).to eql(upcased_subject)
      end

      it "passes extra arguments to a block" do
        result = subject.fmap(:foo, :bar) do |value, c1, c2|
          expect(value).to eql("foo")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        expect(result).to eql(some[true])
      end

      it "passes extra arguments to a proc" do
        proc = lambda do |value, c1, c2|
          expect(value).to eql("foo")
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          true
        end

        result = subject.fmap(proc, :foo, :bar)

        expect(result).to eql(some[true])
      end
    end

    describe "#maybe" do
      it "is an alias for fmap" do
        expect(subject.method(:maybe)).to eql(subject.method(:fmap))
      end
    end

    describe "#or" do
      it "accepts a value as an alternative" do
        expect(subject.or(some["baz"])).to be(subject)
      end

      it "accepts a block as an alternative" do
        expect(subject.or { raise }).to be(subject)
      end

      it "ignores all values" do
        expect(subject.or(:foo, :bar, :baz) { raise }).to be(subject)
      end
    end

    describe "#or_fmap" do
      it "accepts a value as an alternative" do
        expect(subject.or_fmap("baz")).to be(subject)
      end

      it "accepts a block as an alternative" do
        expect(subject.or_fmap { raise }).to be(subject)
      end

      it "ignores all values" do
        expect(subject.or_fmap(:foo, :bar, :baz) { raise }).to be(subject)
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

    describe "#to_maybe" do
      let(:subject) { some["foo"].to_maybe }

      it { is_expected.to eql some["foo"] }
    end

    describe "#to_result" do
      it "transforms self to Result::Success" do
        expect(subject.to_result("baz")).to eql(success["foo"])
        expect(subject.to_result { "baz" }).to eql(success["foo"])
      end
    end

    describe "#tee" do
      it "passes through itself when the block returns a Right" do
        expect(subject.tee(->(*) { some["ignored"] })).to be(subject)
      end

      it "returns the block result when it is None" do
        expect(subject.tee(->(*) { none })).to be_none
      end
    end

    describe "#some?/#success?" do
      it "returns true" do
        expect(subject).to be_some
        expect(subject).to be_success
      end
    end

    describe "#none?/#failure?" do
      it "returns false" do
        expect(subject).not_to be_none
        expect(subject).not_to be_failure
      end
    end

    describe "#apply" do
      subject { some[:upcase.to_proc] }

      it "applies a wrapped function" do
        expect(subject.apply(some["foo"])).to eql(some["FOO"])
        expect(subject.apply(none)).to eql(none)
      end
    end

    # rubocop:disable Style/CaseEquality
    describe "#===" do
      it "matches on the wrapped value" do
        expect(some["foo"]).to be === some["foo"]
        expect(some[/\w+/]).to be === some["foo"]
        expect(some[:bar]).not_to be === some["foo"]
        expect(some[10..50]).to be === some[42]
      end
    end
    # rubocop:enable Style/CaseEquality

    describe "#discard" do
      it "nullifies the value" do
        expect(some["foo"].discard).to eql(some[unit])
      end
    end

    describe "#flatten" do
      it "removes one level of monad" do
        expect(some[some["foo"]].flatten).to eql(some["foo"])
      end

      it "returns None for Some(None)" do
        expect(some[none].flatten).to eql(none)
      end
    end

    describe "#and" do
      it "joins two maybe values with a block" do
        expect(some["foo"].and(some["bar"]) { |foo, bar| [foo, bar] }).to eql(some[%w[foo bar]])
      end

      it "returns none if argument is none" do
        expect(some["foo"].and(none) { |_foo, _bar| raise }).to eql(none)
      end

      it "returns a tuple if no block given" do
        expect(some["foo"].and(some["bar"])).to eql(some[%w[foo bar]])
        expect(some["foo"].and(none)).to eql(none)
      end
    end
  end

  describe maybe::None do
    subject { described_class.new }

    it_behaves_like "a monad"

    it { is_expected.not_to be_some }
    it { is_expected.to be_none }

    it { is_expected.to eql(described_class.new) }
    it { is_expected.not_to eql(some["foo"]) }

    it "dumps to string" do
      expect(subject.to_s).to eql("None")
    end

    it "has custom inspection" do
      expect(subject.inspect).to eql("None")
    end

    describe ".missing_method" do
      it "shows a friendly error messsage if an instance method is called" do
        expect { described_class.fmap }.to raise_error(
          Dry::Monads::ConstructorNotAppliedError,
          /None\(\)/
        )
      end

      it "throws NoMethodError on everything else" do
        described_class.garbage
      rescue StandardError => e
        expect(e.class).to be(NoMethodError)
      end
    end

    describe "#initialize" do
      it "traces the caller" do
        expect(subject.trace).to include("spec/unit/maybe_spec.rb")
      end
    end

    describe "#value!" do
      it "raises an error" do
        expect { subject.value! }.to raise_error(Dry::Monads::UnwrapError, "value! was called on None")
      end
    end

    describe "#bind" do
      it "accepts a proc and returns itself" do
        expect(subject.bind(upcase)).to be subject
      end

      it "accepts a block and returns itself" do
        expect(subject.bind(&:upcase)).to be subject
      end

      it "ignores arguments" do
        expect(subject.bind(1, 2, 3) { raise }).to be subject
      end
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

    describe "#maybe" do
      it "is an alias for fmap" do
        expect(subject.maybe { raise }).to be(subject)
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
        result = subject.or(:foo, :bar) do |c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          "baz"
        end

        expect(result).to eql("baz")
      end
    end

    describe "#or_fmap" do
      it "maps an alternative" do
        expect(subject.or_fmap("baz")).to eql(some["baz"])
      end

      it "accepts a block" do
        expect(subject.or_fmap { "baz" }).to eql(some["baz"])
      end

      it "passes extra arguments to a block" do
        result = subject.or_fmap(:foo, :bar) do |c1, c2|
          expect(c1).to eql(:foo)
          expect(c2).to eql(:bar)
          "baz"
        end

        expect(result).to eql(some["baz"])
      end

      it "tranforms nil to None" do
        expect(subject.or_fmap(nil)).to eql(none)
      end
    end

    describe "#value_or" do
      it "returns passed value" do
        expect(subject.value_or("baz")).to eql("baz")
      end

      it "executes a block" do
        expect(subject.value_or { "bar" }).to eql("bar")
      end
    end

    describe "#to_maybe" do
      let(:subject) { none.to_maybe }

      it { is_expected.to eql maybe::None.new }
    end

    describe "#to_result" do
      it "transforms self to Result::Failure" do
        expect(subject.to_result("bar")).to eql(failure["bar"])
        expect(subject.to_result { "bar" }).to eql(failure["bar"])
        expect(subject.to_result).to eql(failure[unit])
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

    describe "#some?/#success?" do
      it "returns true" do
        expect(subject).not_to be_some
        expect(subject).not_to be_success
      end
    end

    describe "#none?/#failure?" do
      it "returns false" do
        expect(subject).to be_none
        expect(subject).to be_failure
      end
    end

    describe "#apply" do
      it "does nothing" do
        expect(subject.apply(some["foo"])).to be(subject)
        expect(subject.apply(none)).to be(subject)
      end
    end

    # rubocop:disable Style/CaseEquality
    describe "#===" do
      it "matches against other None" do
        expect(none).to be === maybe::None.new
      end

      it "doesn't match a Some" do
        expect(none).not_to be === some["foo"]
      end
    end
    # rubocop:enable Style/CaseEquality

    describe "#discard" do
      it "returns self back" do
        expect(none.discard).to be none
      end
    end

    describe "#flatten" do
      it "always return None" do
        expect(none.flatten).to eql(none)
      end
    end

    describe "#and" do
      it "always return None" do
        expect(none.and(some["foo"]) { raise }).to eql(none)
        expect(none.and(some["foo"])).to eql(none)
        expect(none.and(none)).to eql(none)
      end
    end
  end

  describe maybe::Mixin do
    subject(:obj) { Object.new.tap { |o| o.extend(maybe::Mixin) } }

    describe "#Some" do
      example "with plain value" do
        expect(subject.Some("thing")).to eql(some["thing"])
      end

      example "with a block" do
        block = -> { "thing" }
        expect(subject.Some(&block)).to eql(some[block])
      end

      it "raises an ArgumentError on missing value" do
        expect(subject.Some()).to eql(some[unit])
      end
    end

    describe "#None" do
      example "tracks the caller" do
        expect(subject.None().trace).to include("spec/unit/maybe_spec.rb")
      end
    end
  end

  describe maybe::Hash do
    let(:hash) { described_class }

    describe ".all" do
      it "traverses all values" do
        expect(hash.all(foo: some["123"], bar: some["234"])).to eql(
          some[foo: "123", bar: "234"]
        )
      end

      it "returns None if any value is None" do
        expect(hash.all(foo: none, bar: some["234"])).to eql(none)
        expect(hash.all(foo: some["123"], bar: none)).to eql(none)
      end

      it "returns Some({}) for an empty hash" do
        expect(hash.all({})).to eql(some[{}])
      end
    end

    describe ".filter" do
      it "keeps some values and unwraps them" do
        expect(hash.filter(foo: some["123"], bar: some["234"])).to eql(
          foo: "123", bar: "234"
        )
      end

      it "skips none values" do
        expect(hash.filter(foo: none, bar: some["234"])).to eql(bar: "234")
        expect(hash.filter(foo: some["123"], bar: none)).to eql(foo: "123")
      end

      it "returns {} for an empty hash" do
        expect(hash.filter({})).to eql({})
      end
    end
  end
end
