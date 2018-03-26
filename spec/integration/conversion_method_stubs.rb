RSpec.describe "Conversion method stubs raising errors" do
  before do
    @loaded_features = $LOADED_FEATURES.dup
    $LOADED_FEATURES.delete_if { |path| path.include?("dry/monads") }

    Dry::Monads.constants.each do |const|
      Dry::Monads.send(:remove_const, const)
    end
    Dry.send(:remove_const, :Monads)
  end

  after do
    require "dry/monads"
  end

  describe "Result" do
    before do
      require "dry/monads/result"
    end

    describe "Success" do
      specify { expect { Dry::Monads::Success('foo').to_maybe }.to raise_error(RuntimeError) }
      specify { expect { Dry::Monads::Success('foo').to_validated }.to raise_error(RuntimeError) }
    end

    describe "Failure" do
      specify { expect { Dry::Monads::Failure('foo').to_maybe }.to raise_error(RuntimeError) }
      specify { expect { Dry::Monads::Failure('foo').to_validated }.to raise_error(RuntimeError) }
    end
  end

  describe "Task" do
  end

  describe "Try" do
  end

  describe "Validated" do
  end
end
