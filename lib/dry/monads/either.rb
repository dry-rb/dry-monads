require 'dry/equalizer'

require 'dry/monads/right_biased'

module Dry
  module Monads
    # Represents a value which is either correct or an error.
    #
    # @api public
    class Either
      include Dry::Equalizer(:right, :left)
      attr_reader :right, :left

      # Returns self, added to keep the interface compatible with other monads.
      #
      # @return [Either::Right, Either::Left]
      def to_either
        self
      end

      # Represents a value that is in a correct state, i.e. everything went right.
      #
      # @api public
      class Right < Either
        include RightBiased::Right

        alias value right

        # @param right [Object] a value in a correct state
        def initialize(right)
          @right = right
        end

        # Returns false
        def left?
          false
        end
        alias failure? left?

        # Returns true
        def right?
          true
        end
        alias success? right?

        # Does the same thing as #bind except it also wraps the value
        # in an instance of Either::Right monad. This allows for easier
        # chaining of calls.
        #
        # @example
        #   Dry::Monads.Right(4).fmap(&:succ).fmap(->(n) { n**2 }) # => Right(25)
        #
        # @param [Array<Object>] args arguments will be transparently passed through to #bind
        # @return [Either::Right]
        def fmap(*args, &block)
          Right.new(bind(*args, &block))
        end

        # @return [String]
        def to_s
          "Right(#{value.inspect})"
        end
        alias inspect to_s

        # @return [Maybe::Some]
        def to_maybe
          Kernel.warn 'Right(nil) transformed to None' if value.nil?
          Dry::Monads::Maybe(value)
        end
      end

      # Represents a value that is in an incorrect state, i.e. something went wrong.
      #
      # @api public
      class Left < Either
        include RightBiased::Left

        alias value left

        # @param left [Object] a value in an error state
        def initialize(left)
          @left = left
        end

        # Returns true
        def left?
          true
        end
        alias failure? left?

        # Returns false
        def right?
          false
        end
        alias success? right?

        # If a block is given passes internal value to it and returns the result,
        # otherwise simply returns the parameter val.
        #
        # @example
        #   Dry::Monads.Left(ArgumentError.new('error message')).or(&:message) # => "error message"
        #
        # @param [Array<Object>] args arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value will be returned
        # @return [Object]
        def or(*args)
          if block_given?
            yield(value, *args)
          else
            args[0]
          end
        end

        # @return [String]
        def to_s
          "Left(#{value.inspect})"
        end
        alias inspect to_s

        # @return [Maybe::None]
        def to_maybe
          Maybe::None.instance
        end
      end

      # A module that can be included for easier access to Either monads.
      module Mixin
        Right = Right
        Left = Left

        # @param value [Object] the value to be stored in the monad
        # @return [Either::Right]
        def Right(value)
          Right.new(value)
        end

        # @param value [Object] the value to be stored in the monad
        # @return [Either::Left]
        def Left(value)
          Left.new(value)
        end
      end
    end
  end
end
