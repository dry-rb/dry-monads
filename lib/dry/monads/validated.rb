require 'dry/monads/maybe'
require 'dry/monads/result'

module Dry
  module Monads
    class Validated

      class << self
        def pure(value = Undefined, &block)
          if value.equal?(Undefined)
            Valid.new(block)
          else
            Valid.new(value)
          end
        end
      end

      def to_monad
        self
      end

      class Valid < Validated
        attr_reader :value

        include Dry::Equalizer(:value!)

        def initialize(value)
          @value = value
        end

        def value!
          @value
        end

        def apply(val = Undefined)
          Undefined.default(val) { yield }.fmap(Curry.(value))
        end

        def fmap(proc = Undefined, &block)
          f = Undefined.default(proc, block)
          self.class.new(f.(value))
        end

        def alt_map(_ = nil)
          self
        end

        def or(*)
          self
        end

        def inspect
          "Valid(#{ @value.inspect })"
        end
        alias_method :to_s, :inspect

        def to_maybe
          Maybe.pure(value!)
        end

        def to_result
          Result.pure(value!)
        end
      end

      class Invalid < Validated
        attr_reader :error

        attr_reader :trace

        include Dry::Equalizer(:error)

        def initialize(error, trace = RightBiased::Left.trace_caller)
          @error = error
          @trace = trace
        end

        def apply(val = Undefined)
          Undefined.default(val) { yield }.alt_map { |v| @error + v }
        end

        def alt_map(proc = nil, &block)
          f = proc || block
          self.class.new(f.(error))
        end

        def fmap(*)
          self
        end

        def or(proc = Undefined, &block)
          Undefined.default(proc, block).call
        end

        def inspect
          "Invalid(#{ @error.inspect })"
        end
        alias_method :to_s, :inspect

        def to_maybe
          Maybe::None.new(RightBiased::Left.trace_caller)
        end

        def to_result
          Result::Failure.new(error, RightBiased::Left.trace_caller)
        end
      end

      module Mixin

        Valid = Valid

        Invalid = Invalid

        def Valid(arg)
          Valid.new(arg)
        end

        def Invalid(arg)
          Invalid.new(arg)
        end
      end
    end
  end
end
