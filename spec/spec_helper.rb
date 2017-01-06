$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if RUBY_ENGINE == 'ruby' && ENV['CI'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

begin
  require 'pry'
rescue LoadError
end

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
