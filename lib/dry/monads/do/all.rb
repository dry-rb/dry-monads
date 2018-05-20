require 'dry/monads/do'

module Dry
  module Monads
    module Do
      module All
        # @private
        class MethodTracker < Module
          attr_reader :wrappers

          def initialize(wrappers)
            super()

            @wrappers = wrappers
            tracker = self

            module_eval do
              define_method(:method_added) do |method|
                super(method)

                tracker.wrap_method(method)
              end
            end
          end

          def extend_object(target)
            super
            target.prepend(wrappers)
          end

          def wrap_method(method)
            Do.wrap_method(wrappers, method)
          end
        end

        # @api public
        def self.included(base)
          super

          base.extend(MethodTracker.new(Module.new))
        end
      end
    end
  end
end
