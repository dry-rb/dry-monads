require 'concurrent/map'

module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api private
  module Monads
    @registry = {}
    @paths = {
      do: 'dry/monads/do/all',
      lazy: 'dry/monads/lazy',
      list: 'dry/monads/list',
      maybe: 'dry/monads/maybe',
      task: 'dry/monads/task',
      try: 'dry/monads/try',
      validated: 'dry/monads/validated',
      result: [
        'dry/monads/result',
        'dry/monads/result/fixed'
      ]
    }.freeze
    @mixins = Concurrent::Map.new

    class << self
      private

      # @private
      def register_mixin(name, mod)
        if @registry.key?(name)
          raise ArgumentError, "#{ name.inspect } is already registered"
        end
        @registry[name] = mod
      end

      # @private
      def known_monads
        @paths.keys
      end

      # @private
      def load_monad(name)
        path = @paths.fetch(name) {
          raise ArgumentError, "#{ name.inspect } is not a known monad"
        }
        Array(path).each { |p| require p }
      end

      # @private
      def unload_monad(name)
        if @registry.key?(name.to_sym)
          @registry = @registry.dup
          @registry.delete(name.to_sym)
        end
      end

      # @private
      def monad_constructors
        @registry.values.map { |m|
          m::Constructors if m.const_defined?(:Constructors)
        }.compact
      end
    end
  end
end
