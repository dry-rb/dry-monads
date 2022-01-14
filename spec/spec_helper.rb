# frozen_string_literal: true

require_relative "support/coverage"
require_relative "support/warnings"
require_relative "support/rspec_options"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "pathname"

SPEC_ROOT = Pathname(__FILE__).dirname

begin
  require "pry"
  require "pry-byebug"
rescue LoadError
end

$VERBOSE = true

require "dry/monads/all"

Dir["./spec/shared/**/*.rb"].sort.each { |f| require f }

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    result
  end
end

module TestHelpers
  def re_require(*paths)
    paths.each { Dry::Monads.unload_monad(_1) }
    all_paths = paths + %w[all]

    $LOADED_FEATURES.delete_if { |feature|
      all_paths.any? { feature.include?("dry/monads/#{_1}.rb") }
    }

    suppress_warnings do
      all_paths.each do
        require "dry/monads/#{_1}"
      end
    end
  end
end

module Dry::Monads
  def self.unload_monad(name)
    if registry.key?(name.to_sym)
      self.registry = registry.reject { |k, _| k.eql?(name.to_sym) }
    end
  end
end

Dry::Core::Deprecations.set_logger!(Logger.new($stdout))

RSpec.configure do |config|
  unless RUBY_VERSION >= "2.7"
    config.exclude_pattern = "**/pattern_matching_spec.rb"
  end

  config.include TestHelpers

  config.before do
    stub_const("Test", Module.new)
  end

  config.around :each, :suppress_deprecations do |ex|
    logger = Dry::Core::Deprecations.logger
    Dry::Core::Deprecations.set_logger!(SPEC_ROOT.join("../log/deprecations.log"))
    ex.run
    Dry::Core::Deprecations.set_logger!(logger)
  end
end
