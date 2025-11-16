source "https://rubygems.org"

###########################################
# Core Rails Framework & Infrastructure
###########################################

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "image_processing", "~> 1.2"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

###########################################
# Development + Test
###########################################

group :development, :test do
  gem "debug", require: "debug/prelude", platforms: %i[mri windows]
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"

  gem "pry-rails"
  gem "better_errors"
  gem "binding_of_caller"
  gem "rack-mini-profiler"
  gem "bullet"
  gem "annotate"
end

###########################################
# Development Only
###########################################

group :development do
  gem "web-console"
end

###########################################
# Test Only
###########################################

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
