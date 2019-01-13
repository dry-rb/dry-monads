RSpec.describe 'Dry::Monads::Either', :suppress_deprecations do
  before { require 'dry/monads/either' }

  before do
    suppress_warnings do
      self.class.include Dry::Monads::Either::Mixin
    end
  end

  specify do
    expect(Right(1)).to eql(Success(1))
    expect(Left(1)).to eql(Failure(1))
  end
end

