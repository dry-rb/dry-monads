module Dry
  module Monads
    module RightBiased
      module Right
        attr_reader :value

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
        def bind(*args, **kwargs)
          vargs, vkwargs = destructure(value)
          kw = kwargs.empty? && vkwargs.empty? ? [] : [kwargs.merge(vkwargs)]

          if block_given?
            yield(*vargs, *args, *kw)
          else
            obj, *rest = args
            obj.call(*vargs, *rest, *kw)
          end
        end

        # Does the same thing as #bind except it returns the original monad
        # when the result is a Right.
        #
        # @example
        #   Dry::Monads.Right(4).tee { Right('ok') } # => Right(4)
        #   Dry::Monads.Right(4).tee { Left('fail') } # => Left('fail')
        #
        # @param [Array<Object>] args arguments will be transparently passed through to #bind
        # @return [RightBiased::Right]
        def tee(*args, &block)
          bind(*args, &block).bind { self }
        end

        # Abstract method for lifting a block over the monad type
        # Must be implemented for a right-biased monad
        #
        # @return [RightBiased::Right]
        def fmap(*)
          raise NotImplementedError
        end

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Left}.
        #
        # @return [RightBiased::Right]
        def or(*)
          self
        end

        # A lifted version of `#or`. For {RightBiased::Right} acts in the same way as `#or`,
        # that is returns itselt.
        #
        # @return [RightBiased::Right]
        def or_fmap(*)
          self
        end

        # Returns value. It exists to keep the interface identical to that of RightBiased::Left
        #
        # @return [Object]
        def value_or(_val = nil)
          value
        end

        private

        # @api private
        def destructure(*args, **kwargs)
          [args, kwargs]
        end
      end

      module Left
        attr_reader :value

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def bind(*)
          self
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def tee(*)
          self
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def fmap(*)
          self
        end

        # Left-biased #bind version.
        #
        # @example
        #   Dry::Monads.Left(ArgumentError.new('error message')).or(&:message) # => "error message"
        #   Dry::Monads.None.or('no value') # => "no value"
        #   Dry::Monads.None.or { Time.now } # => current time
        #
        # @return [Object]
        def or(*)
          raise NotImplementedError
        end

        # A lifted version of `#or`. This is basically `#or` + `#fmap`.
        #
        # @example
        #   Dry::Monads.None.or('no value') # => Some("no value")
        #   Dry::Monads.None.or { Time.now } # => Some(current time)
        #
        # @return [RightBiased::Left, RightBiased::Right]
        def or_fmap(*)
          raise NotImplementedError
        end

        # Returns the passed value
        #
        # @returns [Object]
        def value_or(val = nil)
          if block_given?
            yield
          else
            val
          end
        end
      end
    end
  end
end
