source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
  gem 'simplecov', require: false
  gem 'warning'
end

group :tools do
  gem 'pry-byebug', platform: :mri
  gem 'pry', platform: :jruby
  gem 'ossy', github: 'solnic/ossy', branch: 'master'
  gem 'benchmark-ips'
end

group :docs do
  gem 'yard'
  gem 'yard-junk'
  gem 'redcarpet'
end
