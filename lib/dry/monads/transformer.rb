# frozen_string_literal: true

module Dry
  module Monads
    # Advanced tranformations.
    module Transformer
      # Lifts a block/proc over the 2-level nested structure.
      # This is essentially fmap . fmap (. is the function composition
      # operator from Haskell) or the functor instance for
      # a two-level monadic structure like List Either.
      #
      # @example
      #   List[Right(1), Left(1)].fmap2 { |x| x + 1 } # => List[Right(2), Left(1)]
      #   Right(None).fmap2 { |x| x + 1 } # => Right(None)
      #
      # @param args [Array<Object>] arguments will be passed to the block or the proc
      # @return [Object] some monadic value
      def fmap2(*args)
        if block_given?
          fmap { |a| a.fmap { |b| yield(b, *args) } }
        else
          func, *rest = args
          fmap { |a| a.fmap { |b| func.(b, *rest) } }
        end
      end

      # Lifts a block/proc over the 3-level nested structure.
      #
      # @example
      #   List[Right(Some(1)), Left(Some(1))].fmap3 { |x| x + 1 }
      #   # => List[Right(Some(2)), Left(Some(1))]
      #   Right(None).fmap3 { |x| x + 1 } # => Right(None)
      #
      # @param args [Array<Object>] arguments will be passed to the block or the proc
      # @return [Object] some monadic value
      def fmap3(*args)
        if block_given?
          fmap { |a| a.fmap { |b| b.fmap { |c| yield(c, *args) } } }
        else
          func, *rest = args
          fmap { |a| a.fmap { |b| b.fmap { |c| func.(c, *rest) } } }
        end
      end
    end
  end
end
