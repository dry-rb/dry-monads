# frozen_string_literal: true

module Dry
  module Monads
    # Validated is similar to Result and represents an outcome of a validation.
    # The difference between Validated and Result is that the former implements
    # `#apply` in a way that concatenates errors. This means that the error type
    # has to have `+` implemented (be a semigroup). This plays nice with arrays and lists.
    # Also, List<Validated>#traverse implicitly uses a block that wraps errors with
    # a list so that you don't have to do it manually.
    #
    # @example using with List
    #   List::Validated[Valid('London'), Invalid(:name_missing), Invalid(:email_missing)]
    #   # => Invalid(List[:name_missing, :email_missing])
    #
    # @example with valid results
    #   List::Validated[Valid('London'), Valid('John')]
    #   # => Valid(List['London', 'John'])
    #
    class Validated
      include ConversionStubs[:to_maybe, :to_result]

      class << self
        # Wraps a value with `Valid`.
        #
        # @overload pure(value)
        #   @param value [Object] value to be wrapped with Valid
        #   @return [Validated::Valid]
        #
        # @overload pure(&block)
        #   @param block [Object] block to be wrapped with Valid
        #   @return [Validated::Valid]
        #
        def pure(value = Undefined, &block)
          Valid.new(Undefined.default(value, block))
        end
      end

      # Returns self.
      #
      # @return [Validated::Valid, Validated::Invalid]
      def to_monad
        self
      end

      # Bind/flat_map is not implemented
      #
      def bind(*)
        # See https://typelevel.org/cats/datatypes/validated.html for details on why
        raise NotImplementedError,
              "Validated is not a monad because it would violate the monad laws"
      end

      # Valid result
      #
      class Valid < Validated
        include Dry::Equalizer(:value!)

        def initialize(value)
          super()

          @value = value
        end

        # Extracts the value
        #
        # @return [Object]
        def value!
          @value
        end

        # Applies another Valid to the stored function
        #
        # @overload apply(val)
        #   @example
        #     Validated.pure { |x| x + 1 }.apply(Valid(2)) # => Valid(3)
        #
        #   @param val [Validated::Valid,Validated::Invalid]
        #   @return [Validated::Valid,Validated::Invalid]
        #
        # @overload apply
        #   @example
        #     Validated.pure { |x| x + 1 }.apply { Valid(4) } # => Valid(5)
        #
        #   @yieldreturn [Validated::Valid,Validated::Invalid]
        #   @return [Validated::Valid,Validated::Invalid]
        #
        def apply(val = Undefined, &block)
          Undefined.default(val, &block).fmap(Curry.(value!))
        end

        # Lifts a block/proc over Valid
        #
        # @overload fmap(proc)
        #   @param proc [#call]
        #   @return [Validated::Valid]
        #
        # @overload fmap
        #   @param block [Proc]
        #   @return [Validated::Valid]
        #
        def fmap(proc = Undefined, &block)
          f = Undefined.default(proc, block)
          self.class.new(f.(value!))
        end

        # Ignores values and returns self, see {Invalid#alt_map}
        #
        # @return [Validated::Valid]
        def alt_map(_ = nil)
          self
        end

        # Ignores arguments, returns self
        #
        # @return [Validated::Valid]
        def or(_ = nil)
          self
        end

        # @return [String]
        def inspect
          if Unit.equal?(@value)
            "Valid()"
          else
            "Valid(#{@value.inspect})"
          end
        end
        alias_method :to_s, :inspect

        # @param other [Object]
        # @return [Boolean]
        def ===(other)
          other.instance_of?(self.class) && value! === other.value!
        end
      end

      # Invalid result
      #
      class Invalid < Validated
        # The value stored inside
        #
        # @return [Object]
        attr_reader :error

        # Line where the value was constructed
        #
        # @return [String]
        # @api public
        attr_reader :trace

        include Dry::Equalizer(:error)

        def initialize(error, trace = RightBiased::Left.trace_caller)
          super()

          @error = error
          @trace = trace
        end

        # Collects errors (ignores valid results)
        #
        # @overload apply(val)
        #   @param val [Validated::Valid,Validated::Invalid]
        #   @return [Validated::Invalid]
        #
        # @overload apply
        #   @yieldreturn [Validated::Valid,Validated::Invalid]
        #   @return [Validated::Invalid]
        #
        def apply(val = Undefined, &block)
          Undefined
            .default(val, &block)
            .alt_map { @error + _1 }
            .fmap { return self }
        end

        # Lifts a block/proc over Invalid
        #
        # @overload alt_map(proc)
        #   @param proc [#call]
        #   @return [Validated::Invalid]
        #
        # @overload alt_map
        #   @param block [Proc]
        #   @return [Validated::Invalid]
        #
        def alt_map(proc = Undefined, &block)
          f = Undefined.default(proc, block)
          self.class.new(f.(error), RightBiased::Left.trace_caller)
        end

        # Ignores the passed argument and returns self
        #
        # @return [Validated::Invalid]
        def fmap(_ = nil)
          self
        end

        # Yields the given callable and returns the result
        #
        # @overload or(proc)
        #   @param proc [#call]
        #   @return [Object]
        #
        # @overload or
        #   @param block [Proc]
        #   @return [Object]
        #
        def or(proc = Undefined, &block)
          Undefined.default(proc, block).call
        end

        # @return [String]
        def inspect
          "Invalid(#{@error.inspect})"
        end
        alias_method :to_s, :inspect

        # @param other [Object]
        # @return [Boolean]
        def ===(other)
          other.instance_of?(self.class) && error === other.error
        end
      end

      # Mixin with Validated constructors
      #
      module Mixin
        # Successful validation result
        # @see Dry::Monads::Validated::Valid
        Valid = Valid

        # Unsuccessful validation result
        # @see Dry::Monads::Validated::Invalid
        Invalid = Invalid

        # Actual constructor methods
        #
        module Constructors
          # Valid constructor
          #
          # @overload Valid(value)
          #   @param value [Object]
          #   @return [Valdated::Valid]
          #
          # @overload Valid(&block)
          #   @param block [Proc]
          #   @return [Valdated::Valid]
          #
          def Valid(value = Undefined, &block)
            v = Undefined.default(value, block)
            raise ArgumentError, "No value given" if !value.nil? && v.nil?

            Valid.new(v)
          end

          # Invalid constructor
          #
          # @overload Invalid(value)
          #   @param value [Object]
          #   @return [Valdated::Invalid]
          #
          # @overload Invalid(&block)
          #   @param block [Proc]
          #   @return [Valdated::Invalid]
          #
          def Invalid(value = Undefined, &block)
            v = Undefined.default(value, block)
            raise ArgumentError, "No value given" if !value.nil? && v.nil?

            Invalid.new(v, RightBiased::Left.trace_caller)
          end
        end

        include Constructors
      end
    end

    extend Validated::Mixin::Constructors

    # @see Validated::Valid
    Valid = Validated::Valid
    # @see Validated::Invalid
    Invalid = Validated::Invalid

    class Result
      class Success < Result
        # Transforms to Validated
        #
        # @return [Validated::Valid]
        def to_validated
          Validated::Valid.new(value!)
        end
      end

      class Failure < Result
        # Transforms to Validated
        #
        # @return [Validated::Invalid]
        def to_validated
          Validated::Invalid.new(failure, trace)
        end
      end
    end

    require "dry/monads/registry"
    register_mixin(:validated, Validated::Mixin)
  end
end
