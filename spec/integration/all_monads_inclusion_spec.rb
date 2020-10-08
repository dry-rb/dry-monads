# frozen_string_literal: true

RSpec.describe "Dry::Monads module mixin" do
  it "raises an error when all monads are not loaded" do
    Dry::Monads.unload_monad(:maybe)

    expect {
      class Test::MyClass
        include Dry::Monads
      end
    }.to raise_error RuntimeError, /Load all monads first/

    re_require "maybe"
  end

  it "raises no error when all monads are loaded" do
    expect {
      class Test::MyClass
        include Dry::Monads
      end
    }.not_to raise_error

    expect(Test::MyClass.constants).to include(:Success)
    expect(Test::MyClass.constants).to include(:Failure)
  end
end
