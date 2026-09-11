# frozen_string_literal: true

require "json"

# Require json 2.15, the first version with everything this extension needs:
#
# - json 2.10 has `JSON::Coder`, but ignores the `on_load:` option
# - json 2.11 through 2.14 never pass the hash key flag to the `as_json` callback
#
# Both of these gaps are silent and may lead to incorrect serialization, so refuse to load instead.
if Gem::Version.new(::JSON::VERSION) < Gem::Version.new("2.15.0")
  raise "The Dry Monads :json extension needs json 2.15.0 or later, but json #{::JSON::VERSION} is loaded"
end

module Dry
  module Monads
    # Reads and writes monads as JSON via `JSON::Coder`.
    #
    # This replaces the old `json/add/dry/monads/maybe` file, no longer working from json 3.0, which
    # removed the whole `json/add` mechanism, so monads can no longer serialize via `JSON.dump` and
    # `JSON.load` globally. A coder does the same job locally, without patching anything.
    #
    # The wire format remains unchanged, so JSON written by older versions still loads.
    #
    # @example
    #   Dry::Monads.load_extensions(:json)
    #
    #   coder = Dry::Monads.json_coder
    #   coder.dump(Some(3)) # => %({"json_class":"Dry::Monads::Maybe::Some","value":3})
    #   coder.load(%({"json_class":"Dry::Monads::Maybe::Some","value":3})) # => Some(3)
    #
    # @api public
    module JSONCoder
      # Key used to tag a serialized monad.
      JSON_CLASS_KEY = "json_class"

      # Called for every object the generator cannot write natively.
      #
      # The second argument is `true` when the object is a hash key and `false` everywhere else. We
      # do not use it, because a monad never appears as a key, but it must be accepted.
      #
      # @api private
      AS_JSON = lambda { |object, *|
        case object
        when Maybe
          {JSON_CLASS_KEY => object.class.name, "value" => object.none? ? nil : object.value!}
        else
          object
        end
      }

      # Called for every value the parser produces, innermost first.
      #
      # @api private
      ON_LOAD = lambda { |value|
        next value unless value.is_a?(::Hash) && value.key?(JSON_CLASS_KEY)

        case value[JSON_CLASS_KEY]
        when Maybe::Some.name then Maybe::Some.new(value["value"])
        when Maybe::None.name then Maybe::None.instance
        else value
        end
      }
    end

    # Returns a coder that reads and writes monads. Unknown objects raise `JSON::GeneratorError`.
    #
    # A `JSON::Coder` is frozen on creation, so you cannot add monad support to an existing coder.
    # Build your coder here instead: provide `as_json:` to write your own types, and `on_load:` to
    # read them back. Both will run after the monad callbacks, and both see every value, so pass
    # through anything you do not recognize.
    #
    # @example a coder that reads and writes monads and times
    #   coder = Dry::Monads.json_coder(
    #     as_json: ->(object, *) {
    #       object.is_a?(Time) ? {"json_class" => "Time", "value" => object.iso8601} : object
    #     },
    #     on_load: ->(value) {
    #       if value.is_a?(Hash) && value["json_class"] == "Time"
    #         Time.iso8601(value["value"])
    #       else
    #         value
    #       end
    #     }
    #   )
    #
    #   coder.dump(Some(Time.utc(2026)))
    #   # => %({"json_class":"Dry::Monads::Maybe::Some","value":{"json_class":"Time","value":"2026-01-01T00:00:00Z"}})
    #
    # Monads nest inside your types and the other way around, because the generator and the
    # parser walk the whole document and call both callbacks at every step.
    #
    # `as_json:` takes a second argument, which is `true` when the object is a hash key, and `false`
    # everywhere else. Use it if you write a type that can be a key, because for a key you must
    # return a String or a Symbol. Anything else raises `JSON::GeneratorError`:
    #
    #   as_json: ->(object, as_key) {
    #     next object unless object.is_a?(Time)
    #     as_key ? object.iso8601 : {"json_class" => "Time", "value" => object.iso8601}
    #   }
    #
    # Even if you don't need this argument, your lambda must accept it (as in `->(object, *)`), or
    # you will see an `ArgumentError` on the first dump.
    #
    # @param as_json [#call, nil] runs on every object the generator cannot write natively, after
    #   the monad callback
    # @param on_load [#call, nil] runs on every parsed value, after the monad callback
    # @param options [Hash] passed on to `JSON::Coder.new`
    # @return [JSON::Coder]
    #
    # @api public
    def self.json_coder(as_json: nil, on_load: nil, **options, &block)
      # `JSON::Coder.new` takes its `as_json` callback as a block. We've opted to make it an keyword
      # argument for consistency alongside `on_load:`.
      #
      # A user familiar with `JSON::Coder` may provide a block, so raise an error just in case.
      raise ArgumentError, "pass the as_json callback as `as_json:`, not as a block" if block

      ::JSON::Coder.new(
        on_load: on_load ? JSONCoder::ON_LOAD >> on_load : JSONCoder::ON_LOAD,
        **options
      ) do |object, as_key|
        json = JSONCoder::AS_JSON.call(object, as_key)
        as_json ? as_json.call(json, as_key) : json
      end
    end
  end
end
