source 'https://rubygems.org'

eval_gemfile 'Gemfile.devtools'

gemspec

group :test do
  gem 'warning'
end

group :tools do
  gem 'pry-byebug', platform: :mri
  gem 'pry', platform: :jruby
  gem 'benchmark-ips'
end

group :docs do
  gem 'yard'
  gem 'yard-junk'
  gem 'redcarpet'
end
