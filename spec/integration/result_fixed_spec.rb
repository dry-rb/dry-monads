require 'dry-types'

RSpec.describe(Dry::Monads::Result) do
  result = Dry::Monads::Result
  failure = result::Failure.method(:new)

  subject { Test::Operation.new }

  context 'dry-types' do
    before do
      module Test
        module Types
          include Dry::Types.module
        end
      end
    end

    context 'errors as failures' do
      before do
        module Test
          class Operation
            Error =
              Types.Instance(ZeroDivisionError) |
              Types.Instance(NoMethodError)

            include Dry::Monads::Result(Error)
          end
        end
      end

      let(:division_error) { 1 / 0 rescue $! }
      let(:no_method_error) { self.missing rescue $! }
      let(:runtime_error) { 'foo'.freeze.upcase! rescue $! }

      it 'passes with known errors' do
        expect(subject.Failure(division_error)).to eql(failure.(division_error))
        expect(subject.Failure(no_method_error)).to eql(failure.(no_method_error))
      end

      it 'raises an error on unexpected type' do
        expect { subject.Failure(runtime_error) }.to raise_error(Dry::Monads::InvalidFailureTypeError)
      end
    end
  end

  context 'arbitrary objects' do
    before do
      module Test
        class Operation
          include Dry::Monads::Result(Symbol)
        end
      end
    end

    it 'wraps symbols with failures' do
      expect(subject.Failure(:no_user)).to eql(failure.(:no_user))
    end

    it 'tracks the caller' do
      error = subject.Failure(:no_user)
      expect(error.trace).to include("spec/integration/result_fixed_spec.rb")
    end

    it 'raises an error on invalid type' do
      expect { subject.Failure("no_user") }.
        to raise_error(
             Dry::Monads::InvalidFailureTypeError,
             %q[Cannot create Failure from "no_user", it doesn't meet the constraints]
           )
    end
  end
end
