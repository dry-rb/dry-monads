# frozen_string_literal: true

module Dry
  # Common, idiomatic monads for Ruby
  #
  # @api private
  module Monads
    @registry = {}
    @constructors = nil
    @constants = {
      do: "Do::All",
      lazy: "Lazy",
      list: "List",
      maybe: "Maybe",
      task: "Task",
      try: "Try",
      validated: "Validated",
      result: [
        "Result",
        "Result::Fixed"
      ]
    }.freeze
    @mixins = ::Concurrent::Map.new

    class << self
      private

      attr_reader :registry

      def registry=(registry)
        @constructors = nil
        @registry = registry.dup.freeze
      end
      protected :registry=

      # @private
      def register_mixin(name, mod)
        if registry.key?(name)
          raise ArgumentError, "#{name.inspect} is already registered"
        end

        self.registry = registry.merge(name => mod)
      end

      # @private
      def known_monads
        @constants.keys
      end

      # @private
      def load_monad(name)
        constants = @constants.fetch(name) {
          raise ::ArgumentError, "#{name.inspect} is not a known monad"
        }
        Array(constants).each do |const_name|
          const_name.split("::").reduce(Monads) { |mod, const| mod.const_get(const) }
        end
      end

      # @private
      def constructors
        @constructors ||= registry.values.filter_map { |m|
          m::Constructors if m.const_defined?(:Constructors)
        }
      end

      # @private
      def all_loaded?
        registry.size.eql?(@constants.size)
      end
    end
  end
end
