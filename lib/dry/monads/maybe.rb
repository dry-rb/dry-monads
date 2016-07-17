module Dry
  module Monads
    # Represents a value which can exist or not, i.e. it could be nil.
    #
    # @api public
    class Maybe
      # Lifts the given value into Maybe::None or Maybe::Some monad.
      #
      # @param value [Object] the value to be stored in the monad
      # @return [Maybe::Some, Maybe::None]
      def self.lift(value)
        if value.nil?
          None.instance
        else
          Some.new(value)
        end
      end

      # @param other [Either]
      # @return [Boolean]
      def ==(other)
        other.is_a?(Maybe) && value == other.value
      end

      # Returns true for an instance of a {Maybe::None} monad.
      def none?
        is_a?(None)
      end

      # Returns true for an instance of a {Maybe::Some} monad.
      def some?
        is_a?(Some)
      end

      # Returns self, added to keep the interface compatible with that of Either monad types.
      #
      # @return [Maybe::Some, Maybe::None]
      def to_maybe
        self
      end

      # Represents a value that is present, i.e. not nil.
      #
      # @api public
      class Some < Maybe
        attr_reader :value

        def initialize(value)
          raise ArgumentError, 'nil cannot be some' if value.nil?
          @value = value
        end

        # Calls the passed in Proc object with value stored in self
        # and returns the result.
        #
        # If proc is nil, it expects a block to be given and will yield to it.
        #
        # @example
        #   Dry::Monads.Some(4).bind(&:succ) # => 5
        #
        # @param proc [Proc, nil]
        # @return [Object] result of calling proc or block on the internal value
        def bind(proc = nil)
          if proc
            proc.call(value)
          else
            yield(value)
          end
        end

        # Does the same thing as #bind except it also wraps the value
        # in an instance of Maybe::Some monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Some(4).fmap(&:succ).fmap(->(n) { n**2 }) # => Some(25)
        #
        # @param proc [Proc, nil]
        # @return [Maybe::Some]
        def fmap(proc = nil, &block)
          self.class.lift(bind(&(proc || block)))
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Maybe::None}.
        #
        # @return [Maybe::Some]
        def or(_val = nil)
          self
        end

        # @return [String]
        def to_s
          "Some(#{value.inspect})"
        end
        alias inspect to_s
      end

      # Represents an absence of a value, i.e. the value nil.
      #
      # @api public
      class None < Maybe
        @instance = new
        singleton_class.send(:attr_reader, :instance)

        # @return [nil]
        def value
          nil
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Maybe::Some}.
        #
        # @return [Maybe::None]
        def bind(_proc = nil)
          self
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Maybe::Some}.
        #
        # @return [Maybe::None]
        def fmap(_proc = nil)
          self
        end

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the parameter val.
        #
        # @example
        #   Dry::Monads.None.or('no value') # => "no value"
        #   Dry::Monads.None.or { Time.now } # => current time
        #
        # @param val [Object, nil]
        # @return [Object]
        def or(val = nil)
          if block_given?
            yield(value)
          else
            val
          end
        end

        # @return [String]
        def to_s
          'None'
        end
        alias inspect to_s
      end

      # A module that can be included for easier access to Maybe monads.
      module Mixin
        Maybe = Maybe
        Some = Some
        None = None

        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::Some, Maybe::None]
        def Maybe(value)
          Maybe.lift(value)
        end

        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::Some]
        def Some(value)
          Some.new(value)
        end

        # @param value [Object] the value to be stored in the monad
        # @return [Maybe::None]
        def None
          None.instance
        end
      end
    end
  end
end
