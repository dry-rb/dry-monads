# frozen_string_literal: true

Dry::Monads.load_extensions(:rspec)

require_relative "rspec_nested_helper"

module RSpecExtHelper
  include NestedHelper

  def make_success(value)
    Success[value]
  end
end
