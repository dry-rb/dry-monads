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
            args[0].call(*vargs, *args.drop(1), *kw)
          end
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
