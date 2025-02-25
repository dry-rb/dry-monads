# frozen_string_literal: true

Dry::Monads.extend(Dry::Core::Extensions)

Dry::Monads.register_extension(:rspec) do
  require "dry/monads/extensions/rspec"
end
