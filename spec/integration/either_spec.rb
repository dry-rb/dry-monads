require 'dry/monads/either'

RSpec.describe 'Dry::Monads::Either', :suppress_deprecations do
  suppress_warnings do
    include Dry::Monads::Either::Mixin
  end

  specify do
    expect(Right(1)).to eql(Success(1))
    expect(Left(1)).to eql(Failure(1))
  end
end

