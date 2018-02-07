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
          arg = val.equal?(Undefined) ? yield : val
          arg.fmap { |x| Curry.(value).(x) }
        end

        def fmap(proc = nil, &block)
          f = proc || block
          self.class.new(f.(value))
        end

        def alt_map(_ = nil)
          self
        end

        def or(*)
          self
        end
      end

      class Invalid < Validated
        attr_reader :error

        include Dry::Equalizer(:error)

        def initialize(error)
          @error = error
        end

        def apply(value = Undefined)
          arg = value.equal?(Undefined) ? yield : value
          arg.alt_map { |val| @error + val }
        end

        def alt_map(proc = nil, &block)
          f = proc || block
          self.class.new(f.(error))
        end

        def fmap(*)
          self
        end

        def or
          yield
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
