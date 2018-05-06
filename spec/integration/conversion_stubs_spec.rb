RSpec.describe "Conversion method stubs raising errors" do
  describe "Result" do
    after do
      re_require "maybe", "validated"
    end

    describe "Success" do
      before do
        # To simulate files like maybe, validated, etc. not being loaded, we
        # simply remove the methods they add, and then re-require the files
        # again afterwards to get the methods back in place (see the `after`
        # hooks)
        Dry::Monads::Result::Success.remove_method :to_maybe
        Dry::Monads::Result::Success.remove_method :to_validated
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Success('foo').to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_validated" do
        expect { Dry::Monads::Success('foo').to_validated }.to raise_error(RuntimeError)
      end
    end

    describe "Failure" do
      before do
        Dry::Monads::Result::Failure.remove_method :to_maybe
        Dry::Monads::Result::Failure.remove_method :to_validated
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Failure('foo').to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_validated" do
        expect { Dry::Monads::Failure('foo').to_validated }.to raise_error(RuntimeError)
      end
    end
  end

  describe "Task" do
    before do
      Dry::Monads::Task.remove_method :to_maybe
      Dry::Monads::Task.remove_method :to_result
    end

    after do
      re_require "maybe", "result"
    end

    specify "#to_maybe" do
      expect { Dry::Monads::Task.new { 'foo' }.to_maybe }.to raise_error(RuntimeError)
    end

    specify "#to_result" do
      expect { Dry::Monads::Task.new { 'foo' }.to_result }.to raise_error(RuntimeError)
    end
  end

  describe "Try" do
    after do
      re_require "maybe", "result"
    end

    describe "Value" do
      before do
        Dry::Monads::Try::Value.remove_method(:to_maybe)
        Dry::Monads::Try::Value.remove_method(:to_result)
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Try(ZeroDivisionError) { 1/1 }.to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_result" do
        expect { Dry::Monads::Try(ZeroDivisionError) { 1/1 }.to_result }.to raise_error(RuntimeError)
      end
    end

    describe "Error" do
      before do
        Dry::Monads::Try::Error.remove_method(:to_maybe)
        Dry::Monads::Try::Error.remove_method(:to_result)
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Try(ZeroDivisionError) { 1/0 }.to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_result" do
        expect { Dry::Monads::Try(ZeroDivisionError) { 1/0 }.to_result }.to raise_error(RuntimeError)
      end
    end
  end

  describe "Validated" do
    after do
      re_require "maybe", "result"
    end

    describe "Valid" do
      before do
        Dry::Monads::Validated::Valid.remove_method(:to_maybe)
        Dry::Monads::Validated::Valid.remove_method(:to_result)
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Valid.new('foo').to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_result" do
        expect { Dry::Monads::Valid.new('foo').to_result }.to raise_error(RuntimeError)
      end
    end

    describe "Invalid" do
      before do
        Dry::Monads::Validated::Invalid.remove_method(:to_maybe)
        Dry::Monads::Validated::Invalid.remove_method(:to_result)
      end

      specify "#to_maybe" do
        expect { Dry::Monads::Invalid.new('foo').to_maybe }.to raise_error(RuntimeError)
      end

      specify "#to_result" do
        expect { Dry::Monads::Invalid.new('foo').to_result }.to raise_error(RuntimeError)
      end
    end
  end

  def re_require(*paths)
    $LOADED_FEATURES.delete_if { |feature|
      paths.any? { |path| feature.include?("dry/monads/#{path}.rb") }
    }

    suppress_warnings do
      paths.each do |path|
        require "dry/monads/#{path}"
      end
    end
  end
end
