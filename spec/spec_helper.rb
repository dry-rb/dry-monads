require_relative 'support/coverage'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pathname'

SPEC_ROOT = Pathname(__FILE__).dirname

require 'warning'
Warning.ignore(/rspec\/core/)
Warning[:experimental] = false if Warning.respond_to?(:[])

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

$VERBOSE = true

require 'dry/monads/all'

Dir["./spec/shared/**/*.rb"].sort.each { |f| require f }

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

module TestHelpers
  def re_require(*paths)
    paths.each { |p| Dry::Monads.unload_monad(p) }
    all_paths = paths + %w(all)

    $LOADED_FEATURES.delete_if { |feature|
      all_paths.any? { |path| feature.include?("dry/monads/#{path}.rb") }
    }

    suppress_warnings do
      all_paths.each do |path|
        require "dry/monads/#{path}"
      end
    end
  end
end

# Namespace holding all objects created during specs
module Test
  def self.remove_constants
    constants.each(&method(:remove_const))
  end
end

module Dry::Monads
  def self.unload_monad(name)
    if registry.key?(name.to_sym)
      self.registry = registry.reject { |k, _| k == name.to_sym }
    end
  end
end

Dry::Core::Deprecations.set_logger!(Logger.new($stdout))

RSpec.configure do |config|
  unless RUBY_VERSION >= '2.7'
    config.exclude_pattern = '**/pattern_matching_spec.rb'
  end
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.include TestHelpers

  config.after do
    Test.remove_constants
  end

  config.around :each, :suppress_deprecations do |ex|
    logger = Dry::Core::Deprecations.logger
    Dry::Core::Deprecations.set_logger!(SPEC_ROOT.join('../log/deprecations.log'))
    ex.run
    Dry::Core::Deprecations.set_logger!(logger)
  end
end
