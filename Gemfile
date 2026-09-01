source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 8.1.3"
# Use postgres as the database for Active Record
gem "pg"
# Use Puma as the app server
gem "puma", "~> 8.0"
# Use SCSS for stylesheets
gem "sassc-rails"
# Use terser as compressor for JavaScript assets (handles ES6+, unlike uglifier)
gem "terser"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Turbo Drive gives fast page navigation without full reloads. Requires importmap-rails
# above it in this file for the asset-pipeline (no npm) install path. Read more: https://turbo.hotwired.dev
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Redis client — backs the Redis cache store, Sidekiq's queues, and the production ActionCable adapter (config/cable.yml).
gem "redis", "~> 5.0"
# Use ActiveModel has_secure_password
gem "bcrypt", "~> 3.1.7"

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem "devise"
gem "jwt"
gem "bootstrap", "~> 5.3.8"
gem "font-awesome-rails"
gem "bootsnap", ">= 1.4.4", require: false
gem "mini_magick"
gem "image_processing"
gem "kaminari"
gem "sidekiq", "~> 8.0"
gem "elasticsearch-model", "~> 8.0"
gem "elasticsearch-rails", "~> 8.0"
# Serve the generated OpenAPI document and its Swagger UI at /api-docs.
gem "rswag-api"
gem "rswag-ui"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [ :mri, :mingw, :x64_mingw ]
  # Adds support for Capybara system testing and selenium driver
  gem "capybara"
  gem "selenium-webdriver"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "bullet"
  gem "rspec-rails"
  gem "rswag-specs"
end

group :test do
  gem "simplecov", require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.5"
  gem "letter_opener"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [ :mingw, :mswin, :x64_mingw, :jruby ]
