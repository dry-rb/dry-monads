# frozen_string_literal: true

RSpec.shared_examples_for 'a monad' do
  describe '#to_monad' do
    it 'returns self' do
      expect(subject.to_monad).to be(subject)
    end
  end
end
