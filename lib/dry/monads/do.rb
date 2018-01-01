module Dry
  module Monads
    module Do
      class Halt < StandardError
        attr_reader :result

        def initialize(result)
          super()

          @result = result
        end
      end

      def self.for(method)
        mod = Module.new do
          define_method(method) do |*args|
            begin
              super(*args) do |*ms|
                unwrapped = ms.map { |m| m.or { halt(m) }.value! }
                ms.size == 1 ? unwrapped[0] : unwrapped
              end
            rescue Halt => e
              e.result
            end
          end
        end

        Module.new do
          singleton_class.send(:define_method, :included) do |base|
            base.prepend(mod)
          end

          def halt(result)
            raise Halt.new(result)
          end
        end
      end
    end
  end
end
