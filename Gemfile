# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"

group :tools do
  gem "benchmark-ips"
  gem "pry", platform: :jruby
  gem "pry-byebug", platform: :mri
end

group :docs do
  gem "redcarpet", platform: :mri
  gem "yard"
  gem "yard-junk"
end
