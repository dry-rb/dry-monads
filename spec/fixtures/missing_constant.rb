# frozen_string_literal: true

class MissingConstant
  def call(value)
    Success[value]
  end
end
