$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'dry-monads'

begin
  require 'pry'
  require 'pry/stack_explorer'
rescue LoadError
end
