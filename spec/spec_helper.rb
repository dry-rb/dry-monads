$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pathname'

SPEC_ROOT = Pathname(__FILE__).dirname


if RUBY_ENGINE == 'ruby' && ENV['COVERAGE'] == 'true'
  require 'yaml'
  rubies = YAML.load(File.read(File.join(__dir__, '..', '.travis.yml')))['rvm']
  latest_mri = rubies.select { |v| v =~ /\A\d+\.\d+.\d+\z/ }.max

  if RUBY_VERSION == latest_mri
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end
  end
end

begin
  require 'pry'
  require 'pry-byebug'
rescue LoadError
end

$VERBOSE = true

require 'dry-monads'

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

# Namespace holding all objects created during specs
module Test
  def self.remove_constants
    constants.each(&method(:remove_const))
  end
end

Dry::Core::Deprecations.set_logger!(Logger.new($stdout))

RSpec.configure do |config|
  config.disable_monkey_patching!

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
