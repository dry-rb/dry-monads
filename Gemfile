# frozen_string_literal: true

source 'https://rubygems.org'

eval_gemfile 'Gemfile.devtools'

gemspec

group :tools do
  gem 'benchmark-ips'
  gem 'pry', platform: :jruby
  gem 'pry-byebug', platform: :mri
end

group :docs do
  gem 'redcarpet'
  gem 'yard'
  gem 'yard-junk'
end
