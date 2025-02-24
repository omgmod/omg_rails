source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.0.8.1', '>= 7.0.1'
# Use postgres as the database for Active Record
gem 'pg', '~> 1.2.3'
# Create data migrations to migrate db content
gem 'rails-data-migrations'
# Allow active record to import in bulk
gem 'activerecord-import'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Pinning to 2.1.0 due to https://github.com/sass/sassc-ruby/issues/189
gem 'sassc', '2.1.0'

gem 'jsbundling-rails'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# AWS S3 SDK, require: false so it's not required when starting the bundler
gem 'aws-sdk-s3', require: false

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

gem 'state_machines-activerecord'

gem 'jsonapi-serializer'

gem 'grape'
gem 'grape-entity'
gem 'grape_logging'

# DB views
gem 'scenic'

# HTTP requests
gem "http"

# Openid
gem 'devise'
gem 'omniauth-steam'
gem 'omniauth-rails_csrf_protection'

gem 'rack-cors'

gem 'thor'
gem "seedbank"

gem 'sidekiq'

gem 'rubyzip', require: false

# Skill rating
gem 'trueskill'

# Pretty printing
gem 'pry'
gem 'pry-rails'
gem 'pry-doc'
gem 'pry-awesome_print'
gem 'awesome_print'

gem 'bundler-audit'

# Sentry
gem "sentry-ruby"
gem "sentry-rails"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

gem 'rspec_junit_formatter'

gem 'dalli'

gem 'json'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec'
  gem 'rspec-rails'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # Annotate models
  gem 'annotate'

  gem 'foreman'

  gem 'grape_on_rails_routes'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "pundit", "~> 2.3"

gem "sprockets-rails"
gem "turbo-rails", "~> 2.0"
gem "net-http", "~> 0.4.1"

gem "rexml" # Seems needed for heroku to build
gem "simple_form", "~> 5.3"
