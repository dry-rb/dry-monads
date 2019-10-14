source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
  gem 'codeclimate-test-reporter', require: false
  gem 'simplecov', require: false
  gem 'warning'
end

group :tools do
  gem 'pry-byebug', platform: :mri
  gem 'pry', platform: :jruby
  gem 'ossy', github: 'solnic/ossy', branch: 'master'
end

group :docs do
  gem 'yard'
  gem 'yard-junk'
  gem 'redcarpet'
end
