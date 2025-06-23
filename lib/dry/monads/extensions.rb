# frozen_string_literal: true

Dry::Monads.extend(Dry::Core::Extensions)

Dry::Monads.register_extension(:rspec) do
  require "dry/monads/extensions/rspec"
end

Dry::Monads.register_extension(:super_diff) do
  require "dry/monads/extensions/super_diff"
end

Dry::Monads.register_extension(:pretty_print) do
  require "dry/monads/extensions/pretty_print"
end
