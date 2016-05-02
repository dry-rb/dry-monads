$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if RUBY_ENGINE == 'ruby'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start

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
