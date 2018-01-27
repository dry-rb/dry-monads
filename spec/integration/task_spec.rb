require 'concurrent/executor/single_thread_executor'

RSpec.describe(Dry::Monads::Task) do
  include Dry::Monads::Result::Mixin

  describe Dry::Monads::Task::Mixin do
    describe 'custom executors' do
      before do
        module Test
          IO = Concurrent::ThreadPoolExecutor.new
          Seq = Concurrent::SingleThreadExecutor.new

          class Operation
            include Dry::Monads::Result::Mixin
            include Dry::Monads::Task::Mixin[IO]
            include Dry::Monads::Do.for(:call)

            def call
              name, age = yield Task { 'Jane' }, Task { 20 }
              city = yield Task[Seq] { 'London' }

              Success(name: name, age: age, city: city)
            end
          end
        end
      end

      let(:operation) { Test::Operation.new }

      it 'executes tasks on the given thread pool' do
        expect(operation.call).to eql(Success(name: 'Jane', age: 20, city: 'London'))
      end
    end
  end

  describe 'global executor' do
    before do
      module Test
        class Operation
          include Dry::Monads::Result::Mixin
          include Dry::Monads::Task::Mixin
          include Dry::Monads::Do.for(:call)

          def call
            name, age = yield Task { 'Jane' }, Task { 20 }
            city = yield Task { 'London' }

            Success(name: name, age: age, city: city)
          end
        end
      end
    end

    let(:operation) { Test::Operation.new }

    it 'executes tasks on the global thread pool' do
      expect(operation.call).to eql(Success(name: 'Jane', age: 20, city: 'London'))
    end
  end
end
