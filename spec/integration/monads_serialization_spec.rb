RSpec.describe 'JSON serialization' do
  include Dry::Monads::Maybe::Mixin

  let(:example_structure) do
    {
      'some' => Some(3),
      'none' => None()
    }
  end

  subject { JSON.load(JSON.dump(example_structure)) }

  it 'cannot deserialize without require the monad class extension' do
    is_expected.not_to eql(example_structure)
  end

  it 'should rebuild the example structure' do
    # Need to create a subprocess with Kernel#fork
    # to have always an unloaded json/add/dry/monads/maybe.rb file
    Kernel.fork do
      # must be required manually to provide the JSON serialization
      # class extension ONLY in the subprocess
      require 'json/add/dry/monads/maybe'

      is_expected.to eql(example_structure)
    end
  end
end
