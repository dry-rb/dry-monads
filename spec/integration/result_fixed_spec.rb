require 'dry-types'

RSpec.describe(Dry::Monads::Result) do
  result = Dry::Monads::Result
  failure = result::Failure.method(:new)

  before do
    module Test
      module Types
        include Dry::Types.module
      end

      class Operation
        wrap_error = -> error { Types::Instance(error).constrained(type: error) }

        Errors =
          wrap_error.(ZeroDivisionError) |
          wrap_error.(NoMethodError)

        include Dry::Monads::Result(Errors)
      end
    end
  end

  subject { Test::Operation.new }

  let(:division_error) { 1 / 0 rescue $! }
  let(:no_method_error) { self.missing rescue $! }
  let(:runtime_error) { 'foo'.freeze.upcase! rescue $! }

  it 'passes with known errors' do
    expect(subject.Failure(division_error)).to eql(failure.(division_error))
    expect(subject.Failure(no_method_error)).to eql(failure.(no_method_error))
  end

  it 'raises an error on unexpected type' do
    expect { subject.Failure(runtime_error) }.to raise_error(Dry::Types::ConstraintError)
  end
end
