lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/monads/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-monads'
  spec.version       = Dry::Monads::VERSION.dup
  spec.authors       = ['Nikita Shilnikov']
  spec.email         = ['fg@flashgordon.ru']
  spec.license       = 'MIT'

  spec.summary       = 'Common monads for Ruby.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/dry-rb/dry-monads'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = ">= 2.2.0"
  spec.add_dependency 'dry-equalizer'
  spec.add_dependency 'dry-core'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
