# frozen_string_literal: true

require 'dry/monads/unit'

RSpec.describe(Dry::Monads::Unit) do
  subject { described_class }

  specify('#to_s') { expect(subject.to_s).to eql('Unit') }
  specify('#inspect') { expect(subject.inspect).to eql('Unit') }
end
