$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'dry-monads'

begin
  require 'pry'
rescue LoadError
end

if RUBY_ENGINE == "rbx"
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end
