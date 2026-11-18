# frozen_string_literal: true

class MissingConstant
  def call(value)
    Success[value]
  end

  def lookup(name) = Object.const_get(name)
end
