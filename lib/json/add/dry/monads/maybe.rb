#frozen_string_literal: false
unless defined?(::JSON::JSON_LOADED) and ::JSON::JSON_LOADED
  require 'json'
end

require 'dry/monads'

# Inspired by standard library implementation
# for Time serialization/deserialization see (json/lib/json/add/time.rb)
# 
class Dry::Monads::Maybe

  # Deserializes JSON string by using Dry::Monads::Maybe#lift method
  def self.json_create(serialized)
    lift(serialized.fetch('value'))
  end

  # Returns a hash, that will be turned into a JSON object and represent this
  # object.
  def as_json(*)
    {
      JSON.create_id => self.class.name,
      value: value
    }
  end

  # Stores class name (Dry::Monads::Maybe::Some or Dry::Monads::Maybe::None)
  # with the monad value as JSON string
  def to_json(*args)
    as_json.to_json(*args)
  end
end
