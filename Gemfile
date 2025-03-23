source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1.1"

# PostgreSQL for development and production (the test suite uses SQLite; see
# config/database.yml).
gem "pg", "~> 1.6"

gem "puma", ">= 7.0"

# JSON serialization for the API responses.
gem "active_model_serializers", "~> 0.10.15"

# Per-IP request throttling (config/initializers/rack_attack.rb).
gem "rack-attack", "~> 6.8"

# Windows does not ship zoneinfo files.
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb.
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "faker"
  # Required by spec/spec_helper.rb, so it must be available in the test group
  # too (a `bundle install --without development` would otherwise break rspec).
  gem "shoulda-matchers"
  # Linter and formatter. Kept out of :development only for the same reason.
  gem "standard", "~> 1.50"
  # SQLite for the test environment so the suite runs without an external
  # Postgres instance. Rails 8 needs sqlite3 2.1 or newer.
  gem "sqlite3", ">= 2.1"
end
