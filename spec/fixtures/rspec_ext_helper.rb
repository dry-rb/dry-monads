# frozen_string_literal: true

Dry::Monads.load_extensions(:rspec)

module RSpecExtHelper
  def make_success(value)
    Success[value]
  end
end
