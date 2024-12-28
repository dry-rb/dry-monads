# frozen_string_literal: true

require "json"

# must be required manually to provide the JSON serialization
require "json/add/dry/monads/maybe"

RSpec.describe "JSON serialization" do
  include Dry::Monads::Maybe::Mixin

  let(:example_structure) do
    {
      "some" => Some(3),
      "none" => None()
    }
  end

  subject { JSON.unsafe_load(JSON.dump(example_structure)) }

  it "should rebuild the example structure" do
    is_expected.to eql(example_structure)
  end
end
