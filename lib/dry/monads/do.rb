module Dry
  module Monads
    module Do
      def self.for(method)
        mod = Module.new do
          define_method(method) do |*args|
            super(*args) do |*ms|
              unwrapped = ms.map { |m| m.or { return m }.value! }
              ms.size == 1 ? unwrapped[0] : unwrapped
            end
          end
        end

        Module.new do
          singleton_class.send(:define_method, :included) do |base|
            base.prepend(mod)
          end
        end
      end
    end
  end
end
