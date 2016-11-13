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
