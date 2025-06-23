# frozen_string_literal: true

module Dry
  module Monads
    module Extensions
      module PrettyPrint
        class PrintValue < ::Module
          def initialize(constructor, accessor: :value!)
            super()

            define_method(:pretty_print) do |pp|
              value = public_send(accessor)

              pp.text "#{constructor}("

              unless Unit.equal?(value)
                pp.group(1) do
                  pp.breakable("")
                  pp.pp(value)
                end
              end
              pp.text ")"
            end
          end
        end

        class LazyPrintValue < ::Module
          def initialize(constructor, success_prefix: "value=", error_prefix: "error=")
            super()

            define_method(:pretty_print) do |pp|
              if promise.fulfilled?
                value = promise.value
                if Unit.equal?(value)
                  if success_prefix.empty?
                    pp.text "#{constructor}()"
                  else
                    pp.text "#{constructor}(#{success_prefix}())"
                  end
                else
                  pp.text "#{constructor}(#{success_prefix}"
                  pp.group(1) do
                    pp.breakable("")
                    pp.pp(value)
                  end
                  pp.text ")"
                end
              elsif promise.rejected?
                pp.text "#{constructor}(#{error_prefix}#{promise.reason.inspect})"
              else
                pp.text "#{constructor}(?)"
              end
            end
          end
        end
      end

      Monads.loader.on_load("Dry::Monads::Maybe") do
        Maybe::Some.include(PrettyPrint::PrintValue.new("Some"))
        Maybe::None.include(::Module.new {
          def pretty_print(pp)
            pp.text "None"
          end
        })
      end

      Monads.loader.on_load("Dry::Monads::Result") do
        Result::Success.include(PrettyPrint::PrintValue.new("Success"))
        Result::Failure.include(PrettyPrint::PrintValue.new("Failure", accessor: :failure))
      end

      Monads.loader.on_load("Dry::Monads::Try") do
        Try::Value.include(PrettyPrint::PrintValue.new("Value"))
        Try::Error.include(PrettyPrint::PrintValue.new("Error", accessor: :exception))
      end

      Monads.loader.on_load("Dry::Monads::List") do
        List.include(PrettyPrint::PrintValue.new("List", accessor: :value))
      end

      Monads.loader.on_load("Dry::Monads::Validated") do
        Validated::Valid.include(PrettyPrint::PrintValue.new("Valid"))
        Validated::Invalid.include(PrettyPrint::PrintValue.new("Invalid", accessor: :error))
      end

      Monads.loader.on_load("Dry::Monads::Task") do
        Task.include(PrettyPrint::LazyPrintValue.new("Task"))
      end

      Monads.loader.on_load("Dry::Monads::Lazy") do
        Lazy.include(
          PrettyPrint::LazyPrintValue.new(
            "Lazy",
            success_prefix: "",
            error_prefix: "error="
          )
        )
      end
    end
  end
end
