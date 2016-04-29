module Dry
  module Monads
    class Either
      attr_reader :right, :left

      def ==(other)
        other.is_a?(Either) && right == other.right && left == other.left
      end

      def right?
        is_a? Right
      end
      alias success? right?

      def left?
        is_a? Left
      end
      alias failure? left?

      class Right < Either
        alias value right

        def initialize(right)
          @right = right
        end

        def bind(proc = nil)
          if proc
            proc.call(value)
          else
            yield(value)
          end
        end
        alias >> bind

        def fmap(proc = nil, &block)
          Right.new(bind(&(proc || block)))
        end

        def or(_val = nil)
          self
        end

        def to_s
          "Right(#{value.inspect})"
        end
        alias inspect to_s

        def to_maybe
          Maybe::Some.new(value)
        end
      end

      class Left < Either
        alias value left

        def initialize(left)
          @left = left
        end

        def bind(_proc = nil)
          self
        end
        alias >> bind

        def fmap(_proc = nil)
          self
        end

        def or(val = nil)
          if block_given?
            yield(value)
          else
            val
          end
        end

        def to_s
          "Left(#{value.inspect})"
        end
        alias inspect to_s

        def to_maybe
          Maybe::None.instance
        end
      end

      module Mixin
        Right = Right
        Left = Left

        def Right(value)
          Right.new(value)
        end

        def Left(value)
          Left.new(value)
        end
      end
    end
  end
end
