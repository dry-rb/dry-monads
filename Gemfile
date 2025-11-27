# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :tools do
  gem "benchmark-ips"
  gem "debug", platforms: :mri
  gem "irb"
end

group :docs do
  gem "redcarpet", platform: :mri
  gem "yard"
  gem "yard-junk"
end

group :test do
  gem "debug_inspector", platforms: :mri
  gem "dry-types"
  gem "super_diff"
end
