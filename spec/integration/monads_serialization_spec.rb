# frozen_string_literal: true

require "time"

RSpec.describe "JSON serialization" do
  include Dry::Monads::Maybe::Mixin

  # must be loaded manually to provide the JSON serialization
  before { Dry::Monads.load_extensions(:json) }

  subject(:coder) { Dry::Monads.json_coder }

  let(:example_structure) do
    {
      "some" => Some(3),
      "none" => None()
    }
  end

  it "serializes and deserializes monads" do
    expect(coder.load(coder.dump(example_structure))).to eql(example_structure)
  end

  it "rebuilds nested monads" do
    nested = Some({"xs" => [None(), Some("y")]})

    expect(coder.load(coder.dump(nested))).to eql(nested)
  end

  it "writes Some as a tagged object" do
    expect(coder.dump(Some(3))).to eql(%({"json_class":"Dry::Monads::Maybe::Some","value":3}))
  end

  it "writes None as a tagged object" do
    expect(coder.dump(None())).to eql(%({"json_class":"Dry::Monads::Maybe::None","value":null}))
  end

  it "reads JSON written by the old json/add serializer" do
    expect(coder.load(%({"json_class":"Dry::Monads::Maybe::Some","value":3}))).to eql(Some(3))
  end

  it "leaves plain JSON alone" do
    expect(coder.load(%({"a":[1,2]}))).to eql({"a" => [1, 2]})
  end

  context "combined with user-defined callbacks" do
    subject(:coder) do
      Dry::Monads.json_coder(
        as_json: ->(object, *) {
          object.is_a?(Time) ? {"json_class" => "Time", "value" => object.iso8601} : object
        },
        on_load: ->(value) {
          if value.is_a?(Hash) && value["json_class"] == "Time"
            Time.iso8601(value["value"])
          else
            value
          end
        }
      )
    end

    let(:time) { Time.utc(2026, 9, 11, 12, 0, 0) }

    it "serializes and deserializes monads" do
      expect(coder.load(coder.dump(example_structure))).to eql(example_structure)
    end

    it "rebuilds the user-defined type" do
      expect(coder.load(coder.dump({"t" => time}))).to eql({"t" => time})
    end

    it "rebuilds a user-defined type nested inside a monad" do
      expect(coder.load(coder.dump(Some(time)))).to eql(Some(time))
    end

    it "rejects an as_json callback given as a block" do
      expect { Dry::Monads.json_coder { |object, *| object } }
        .to raise_error(ArgumentError, /as_json:/)
    end
  end
end
