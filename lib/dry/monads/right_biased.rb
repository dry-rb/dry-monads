require 'dry/core/constants'

require 'dry/monads/curry'
require 'dry/monads/errors'

module Dry
  module Monads
    # A common module for right-biased monads, such as Result/Either, Maybe, and Try.
    module RightBiased
      # Right part
      #
      # @api public
      module Right
        include Dry::Core::Constants

        # Unwraps the underlying value
        #
        # @return [Object]
        def value!
          @value
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
        def bind(*args, **kwargs)
          if args.empty? && !kwargs.empty?
            vargs, vkwargs = destructure(@value)
            kw = [kwargs.merge(vkwargs)]
          else
            vargs = [@value]
            kw = kwargs.empty? ? EMPTY_ARRAY : [kwargs]
          end

          if block_given?
            yield(*vargs, *args, *kw)
          else
            obj, *rest = args
            obj.(*vargs, *rest, *kw)
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

        # Abstract method for lifting a block over the monad type.
        # Must be implemented for a right-biased monad.
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
          @value
        end

        # Applies the stored value to the given argument if the argument has type of Right,
        # otherwise returns the argument.
        #
        # @example happy path
        #   create_user = Dry::Monads::Right(CreateUser.new)
        #   name = Right("John")
        #   create_user.apply(name) # equivalent to CreateUser.new.call("John")
        #
        # @example unhappy path
        #   name = Left(:name_missing)
        #   create_user.apply(name) # => Left(:name_missing)
        #
        # @return [RightBiased::Left,RightBiased::Right]
        def apply(val = Undefined)
          unless @value.respond_to?(:call)
            raise TypeError, "Cannot apply #{ val.inspect } to #{ @value.inspect }"
          end

          arg = val.equal?(Undefined) ? yield : val
          arg.fmap { |unwrapped| curry.(unwrapped) }
        end

        # @param other [RightBiased]
        # @return [Boolean]
        def ===(other)
          self.class == other.class && value! === other.value!
        end

        private

        # @api private
        def destructure(*args, **kwargs)
          [args, kwargs]
        end

        # @api private
        def curry
          @curried ||= Curry.(@value)
        end
      end

      # Left/wrong/erroneous part
      #
      # @api public
      module Left
        # @private
        # @return [String] Caller location
        def self.trace_caller
          caller_locations(2, 2)[0].to_s
        end

        # Raises an error on accessing internal value
        def value!
          raise UnwrapError.new(self)
        end

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
        # @return [Object]
        def value_or(val = nil)
          if block_given?
            yield
          else
            val
          end
        end

        # Ignores the input parameter and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def apply(*)
          self
        end
      end
    end
  end
end
