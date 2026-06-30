# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

# Work around RDoc/JRuby incompatibiltiy: rdoc 8 depends on rbs 4, whose native C extension can't
# build on JRuby.
#
# Remove this once https://github.com/ruby/rdoc/issues/1746 is resolved.
gem "rdoc", "< 8.0"

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
