# frozen_string_literal: true

module Dry
  module Monads
    # A common module for right-biased monads, such as Result/Either, Maybe, and Try.
    module RightBiased
      # Right part
      #
      # @api public
      module Right
        # @private
        def self.included(m)
          super

          def m.to_proc
            @to_proc ||= method(:new).to_proc
          end
          m.singleton_class.alias_method(:call, :new)
        end

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
        def tee(...)
          bind(...).bind { self }
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

        # Ignores arguments and returns self. It exists to keep the interface
        # identical to that of {RightBiased::Left}.
        #
        # @param _alt [RightBiased::Right, RightBiased::Left]
        #
        # @return [RightBiased::Right]
        def |(_alt)
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
        #   create_user = Dry::Monads::Success(CreateUser.new)
        #   name = Success("John")
        #   create_user.apply(name) # equivalent to CreateUser.new.call("John")
        #
        # @example unhappy path
        #   name = Failure(:name_missing)
        #   create_user.apply(name) # => Failure(:name_missing)
        #
        # @return [RightBiased::Left,RightBiased::Right]
        def apply(val = Undefined, &block)
          unless @value.respond_to?(:call)
            raise TypeError, "Cannot apply #{val.inspect} to #{@value.inspect}"
          end

          Undefined.default(val, &block).fmap { curry.(_1) }
        end

        # @param other [Object]
        # @return [Boolean]
        def ===(other)
          other.instance_of?(self.class) && value! === other.value!
        end

        # Maps the value to Dry::Monads::Unit, useful when you don't care
        # about the actual value.
        #
        # @example
        #   Dry::Monads::Success(:success).discard
        #   # => Success(Unit)
        #
        # @return [RightBiased::Right]
        def discard
          fmap { Unit }
        end

        # Removes one level of monad structure by joining two values.
        #
        # @example
        #   include Dry::Monads::Result::Mixin
        #   Success(Success(5)).flatten # => Success(5)
        #   Success(Failure(:not_a_number)).flatten # => Failure(:not_a_number)
        #   Failure(:not_a_number).flatten # => Failure(:not_a_number)
        #
        # @return [RightBiased::Right,RightBiased::Left]
        def flatten
          bind(&:itself)
        end

        # Combines the wrapped value with another monadic value.
        # If both values are right-sided, yields a block and passes a tuple
        # of values there. If no block given, returns a tuple of values wrapped with
        # a monadic structure.
        #
        # @example
        #   include Dry::Monads::Result::Mixin
        #
        #   Success(3).and(Success(5)) # => Success([3, 5])
        #   Success(3).and(Failure(:not_a_number)) # => Failure(:not_a_number)
        #   Failure(:not_a_number).and(Success(5)) # => Failure(:not_a_number)
        #   Success(3).and(Success(5)) { |a, b| a + b } # => Success(8)
        #
        # @param mb [RightBiased::Left,RightBiased::Right]
        #
        # @return [RightBiased::Left,RightBiased::Right]
        def and(mb)
          bind do |a|
            mb.fmap do |b|
              if block_given?
                yield([a, b])
              else
                [a, b]
              end
            end
          end
        end

        # Pattern matching
        #
        # @example
        #   case Success(x)
        #   in Success(Integer) then ...
        #   in Success(2..100) then ...
        #   in Success(2..200 => code) then ...
        #   end
        #
        # @api private
        def deconstruct
          if Unit.equal?(@value)
            EMPTY_ARRAY
          elsif !@value.is_a?(::Array)
            [@value]
          else
            @value
          end
        end

        # Pattern matching hash values
        #
        # @example
        #   case Success(x)
        #   in Success(code: 200...300) then :ok
        #   in Success(code: 300...400) then :redirect
        #   in Success(code: 400...500) then :user_error
        #   in Success(code: 500...600) then :server_error
        #   end
        #
        # @api private
        def deconstruct_keys(keys)
          if @value.respond_to?(:deconstruct_keys)
            @value.deconstruct_keys(keys)
          else
            EMPTY_HASH
          end
        end

        private

        # @api private
        def destructure(value)
          if value.is_a?(::Hash)
            [EMPTY_ARRAY, value]
          else
            [[value], EMPTY_HASH]
          end
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
          caller_locations(2, 1)[0].to_s
        end

        # Raises an error on accessing internal value
        def value!
          raise UnwrapError, self
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

        # Returns the passed value. Works in pair with {RightBiased::Right#|}.
        #
        # @param alt [RightBiased::Right, RightBiased::Left]
        #
        # @return [RightBiased::Right, RightBiased::Left]
        def |(alt)
          self.or(alt)
        end

        # A lifted version of `#or`. This is basically `#or` + `#fmap`.
        #
        # @example
        #   Dry::Monads.None.or_fmap('no value') # => Some("no value")
        #   Dry::Monads.None.or_fmap { Time.now } # => Some(current time)
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

        # Returns self back. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def discard
          self
        end

        # Returns self back. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def flatten
          self
        end

        # Returns self back. It exists to keep the interface
        # identical to that of {RightBiased::Right}.
        #
        # @return [RightBiased::Left]
        def and(_)
          self
        end

        # Pattern matching
        #
        # @example
        #   case Success(x)
        #   in Success(Integer) then ...
        #   in Success(2..100) then ...
        #   in Success(2..200 => code) then ...
        #   in Failure(_) then ...
        #   end
        #
        # @api private
        def deconstruct
          if Unit.equal?(@value)
            []
          elsif @value.is_a?(::Array)
            @value
          else
            [@value]
          end
        end

        # Pattern matching hash values
        #
        # @example
        #   case Failure(x)
        #   in Failure(code: 400...500) then :user_error
        #   in Failure(code: 500...600) then :server_error
        #   end
        #
        # @api private
        def deconstruct_keys(keys)
          if @value.respond_to?(:deconstruct_keys)
            @value.deconstruct_keys(keys)
          else
            EMPTY_HASH
          end
        end
      end
    end
  end
end
