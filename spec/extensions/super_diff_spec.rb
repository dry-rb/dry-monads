# frozen_string_literal: true

require "super_diff"

RSpec.describe "SuperDiff extension" do
  let(:output_start_marker) do
    /(expected:)|(Expected )/
  end

  let(:output_end_marker) do
    /#{output_start_marker.source}|Finished/
  end

  def run_spec(code)
    temp_spec = Tempfile.new(["failing_spec", ".rb"])
    temp_spec.write(<<~RUBY)
      require "dry/monads"

      RSpec.describe "A failing example" do
        include Dry::Monads::Result::Mixin
        include Dry::Monads::Maybe::Mixin
        include Dry::Monads::Try::Mixin

        before(:all) do
          Dry::Monads.load_extensions(:super_diff, :rspec)
        end

        it "fails with a diff" do
          #{code}
        end
      end
    RUBY
    temp_spec.close

    process_output(`rspec --no-color #{temp_spec.path}`, temp_spec.path)
  end

  def process_output(output, path)
    uncolored = output.gsub(/\e\[([;\d]+)?m/, "")
    # cut out significant lines
    lines = extract_diff(uncolored, path)
    prefix = lines.filter_map { |line|
      line.match(/^\A(\s+)/).to_s unless line.strip.empty?
    }.min
    processed_lines = lines.map { |line| line.gsub(prefix, "") }
    remove_banner(processed_lines).join.gsub("\n\n\n", "\n\n").gsub(/\n\n\z/, "\n")
  end

  # remove this part from the output:
  #
  # Diff:
  #
  # ┌ (Key) ──────────────────────────┐
  # │ ‹-› in expected, not in actual  │
  # │ ‹+› in actual, not in expected  │
  # │ ‹ › in both expected and actual │
  # └─────────────────────────────────┘
  #
  def remove_banner(lines)
    before_banner = lines.take_while { |line| !line.start_with?("Diff:") }
    after_banner = lines.drop_while { |line|
      !line.include?("└")
    }.drop(1)
    before_banner + after_banner
  end

  def extract_diff(output, path)
    output.lines.drop_while { |line|
      !line[output_start_marker]
    }.take_while.with_index { |line, idx|
      idx.zero? || !(line.include?(path) || line[output_start_marker])
    }
  end

  context "Result" do
    context "Success" do
      context "eql?" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Success(1)).to eql(Success(2))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Success(2)
                 got: Success(1)

            (compared using eql?)

              Success(
            -   2
            +   1
              )
          DIFF
        end

        example "hash" do
          output = run_spec(<<~RUBY)
            expect(
              Success(a: 1, b: 2)
            ).to eql(Success(a: 2, c: 2))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Success({ a: 2, c: 2 })
                 got: Success({ a: 1, b: 2 })

            (compared using eql?)

              Success(
                {
            -     a: 2,
            +     a: 1,
            -     c: 2
            +     b: 2
                }
              )
          DIFF
        end

        example "with value on expected side" do
          output = run_spec(<<~RUBY)
            expect(Success()).to eql(Success(1))
          RUBY

          expect(output).to include(<<~DIFF)
            expected: Success(1)
                 got: Success()

            (compared using eql?)

              Success(
            -   1
              )
          DIFF
        end

        example "with value on actual side" do
          output = run_spec(<<~RUBY)
            expect(Success(1)).to eql(Success())
          RUBY

          expect(output).to include(<<~DIFF)
            expected: Success()
                 got: Success(1)

            (compared using eql?)

              Success(
            +   1
              )
          DIFF
        end
      end

      context "==" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Success(1)).to eq(Success(2))
          RUBY

          expect(output).to eql(<<~DIFF)
            Expected Success(1) to eq Success(2).

              Success(
            -   2
            +   1
              )
          DIFF
        end

        example "with value on expected side" do
          output = run_spec(<<~RUBY)
            expect(Success()).to eq(Success(1))
          RUBY

          expect(output).to eql(<<~DIFF)
            Expected Success() to eq Success(1).

              Success(
            -   1
              )
          DIFF
        end

        example "with value on actual side" do
          output = run_spec(<<~RUBY)
            expect(Success(1)).to eq(Success())
          RUBY

          expect(output).to eql(<<~DIFF)
            Expected Success(1) to eq Success().

              Success(
            +   1
              )
          DIFF
        end
      end
    end

    context "Failure" do
      context "eql?" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Failure(1)).to eql(Failure(2))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Failure(2)
                 got: Failure(1)

            (compared using eql?)

              Failure(
            -   2
            +   1
              )
          DIFF
        end

        example "with value on expected side" do
          output = run_spec(<<~RUBY)
            expect(Failure()).to eql(Failure(1))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Failure(1)
                 got: Failure()

            (compared using eql?)

              Failure(
            -   1
              )
          DIFF
        end

        example "with arrays" do
          output = run_spec(<<~RUBY)
            expect(Failure[:error, :a]).to eql(Failure[:error, :b])
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Failure[:error, :b]
                 got: Failure[:error, :a]

            (compared using eql?)

              Failure[
                :error,
            -   :b
            +   :a
              ]
          DIFF
        end

        example "mix of arrays and hashes" do
          output = run_spec(<<~RUBY)
            expect(Failure[:error]).to eql(Failure(:error))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Failure(:error)
                 got: Failure[:error]

            (compared using eql?)

              Failure(
            -   :error
            +   [
            +     :error
            +   ]
              )
          DIFF
        end

        example "mix of array and other values" do
          output = run_spec(<<~RUBY)
            expect(Failure[:error]).to eql(1)
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: 1
                 got: Failure[:error]

            (compared using eql?)
          DIFF

          output = run_spec(<<~RUBY)
            obj = Object.new
            expect(obj).to eql(Failure[:error])
          RUBY

          expect(output).to match(Regexp.new(<<~DIFF.chomp, Regexp::MULTILINE))
            expected: Failure\\[:error\\]
                 got: #<Object:0x[0-9a-f]+>

            \\(compared using eql\\?\\)
          DIFF
        end
      end
    end
  end

  context "Maybe" do
    context "Some" do
      context "eql?" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Some(1)).to eql(Some(2))
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Some(2)
                 got: Some(1)

            (compared using eql?)

              Some(
            -   2
            +   1
              )
          DIFF
        end

        example "with None on expected side" do
          output = run_spec(<<~RUBY)
            expect(Some(1)).to eql(None())
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: None()
                 got: Some(1)

            (compared using eql?)
          DIFF
        end
      end

      context "==" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Some(1)).to eq(Some(2))
          RUBY

          expect(output).to eql(<<~DIFF)
            Expected Some(1) to eq Some(2).

              Some(
            -   2
            +   1
              )
          DIFF
        end
      end
    end
  end

  context "Try" do
    context "Value" do
      context "eql?" do
        example "with values on both sides" do
          output = run_spec(<<~RUBY)
            expect(Try { 1 }).to eql(Try { 2 })
          RUBY

          expect(output).to eql(<<~DIFF)
            expected: Value(2)
                 got: Value(1)

            (compared using eql?)

              Value(
            -   2
            +   1
              )
          DIFF
        end
      end
    end
  end
end
