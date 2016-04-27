module Dry
  module Monads
    class Maybe
      def self.lift(value)
        if value.nil?
          None.instance
        else
          Some.new(value)
        end
      end

      def ==(other)
        other.is_a?(Maybe) && value == other.value
      end

      class Some < Maybe
        attr_reader :value

        def initialize(value)
          raise ArgumentError.new('nil cannot be some') if value.nil?
          @value = value
        end

        def bind(proc = nil)
          if block_given?
            yield(value)
          else
            proc.call(value)
          end
        end
        alias >> bind

        def fmap(proc = nil, &block)
          self.class.lift(bind(&(proc || block)))
        end

        def or(_val = nil)
          self
        end

        def to_s
          "Some(#{value.inspect})"
        end
        alias inspect to_s
      end

      class None < Maybe
        @instance = new
        singleton_class.send(:attr_reader, :instance)

        def value
          nil
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
            if val.nil?
              yield
            else
              raise ArgumentError.new('You can pass a block or a value, not both')
            end
          else
            val
          end
        end

        def to_s
          'None'
        end
        alias inspect to_s
      end

      module Mixin
        Maybe = Maybe
        Some = Some
        None = None

        def Maybe(value)
          Maybe.lift(value)
        end

        def Some(value)
          Some.new(value)
        end

        def None
          None.instance
        end
      end
    end
  end
end
