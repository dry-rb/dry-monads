require 'dry/equalizer'

module Dry
  module Monads
    # Represents a value which is either correct or an error.
    #
    # @api public
    class Either
      include Dry::Equalizer(:right, :left)
      attr_reader :right, :left

      # Returns true for an instance of a {Either::Right} monad.
      def right?
        is_a? Right
      end
      alias success? right?

      # Returns true for an instance of a {Either::Left} monad.
      def left?
        is_a? Left
      end
      alias failure? left?

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
        alias value right

        # @param right [Object] a value in a correct state
        def initialize(right)
          @right = right
        end

        # Calls the passed in Proc object with value stored in self
        # and returns the result.
        #
        # If proc is nil, it expects a block to be given and will yield to it.
        #
        # @example
        #   Dry::Monads.Right(4).bind(&:succ) # => 5
        #
        # @param [Array<Object>] args arguments that will be passed to a block
        #                             if one was given, otherwise the first
        #                             value assumed to be a Proc (callable)
        #                             object and the rest of args will be passed
        #                             to this object along with the internal value
        # @return [Object] result of calling proc or block on the internal value
        def bind(*args)
          if block_given?
            yield(value, *args)
          else
            args[0].call(value, *args.drop(1))
          end
        end

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

        # Does the same thing as #bind except it returns the original monad
        # when the result is a Right.
        #
        # @example
        #   Dry::Monads.Right(4).tee { Right('ok') } # => Right(4)
        #   Dry::Monads.Right(4).tee { Left('fail') } # => Left('fail')
        #
        # @param [Array<Object>] args arguments will be transparently passed through to #bind
        # @return [Either]
        def tee(*args, &block)
          bind(*args, &block).bind { self }
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {Either::Left}.
        #
        # @return [Either::Right]
        def or(*)
          self
        end

        # @return [String]
        def to_s
          "Right(#{value.inspect})"
        end
        alias inspect to_s

        # @return [Maybe::Some]
        def to_maybe
          if value.nil?
            Kernel.warn('Unexpected coercion: Right(nil) will be coerced into None')
          end

          Dry::Monads::Maybe(value)
        end
      end

      # Represents a value that is in an incorrect state, i.e. something went wrong.
      #
      # @api public
      class Left < Either
        alias value left

        # @param left [Object] a value in an error state
        def initialize(left)
          @left = left
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Either::Right}.
        #
        # @return [Either::Left]
        def bind(*)
          self
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Either::Right}.
        #
        # @return [Either::Left]
        def fmap(*)
          self
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {Either::Right}.
        #
        # @return [Either::Left]
        def tee(*)
          self
        end

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
