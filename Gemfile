source "https://rubygems.org"
ruby "3.2.4"

# === Core Framework ===
gem "rails", "~> 7.1.4"
gem "sprockets-rails", "~> 3.4.2"
gem "importmap-rails", "~> 1.2.3"
gem "turbo-rails", "~> 1.5.0"
gem "stimulus-rails", "~> 1.3.0"
gem "jbuilder", "~> 2.7"
gem "bootsnap", "~> 1.17.0", require: false

# === Database ===
gem "mysql2", "~> 0.5.5"           # 開発環境
gem "pg", "~> 1.5.4"               # 本番環境

# === Authentication ===
gem "bcrypt", "~> 3.1.20"

# === UI Framework（Rails 7.1互換性確認済み）===
gem "bootstrap-sass", "~> 3.4.1"
gem "sassc-rails", "~> 2.1.2"      # bootstrap-sass必須依存
gem "jquery-rails", "~> 4.6.0"     # Bootstrap JS依存

# === Pagination & I18n ===
gem "kaminari", "~> 1.2.2"
gem "rails-i18n", "~> 7.0.8"

# === Server ===
gem "puma", ">= 5.0"

# === Development Dependencies ===
group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem "rspec-rails", "~> 6.1.0"
  gem "factory_bot_rails", "~> 6.4.3"
  gem "faker", "~> 3.2.2"
end

group :development do
  gem "web-console", "~> 4.2.1"
  gem "listen", "~> 3.8.0"
  gem "rubocop", "~> 1.57.2"
  gem "rubocop-rails", "~> 2.22.2"
  gem "rubocop-rspec", "~> 2.25.0"
end

group :test do
  gem "capybara", "~> 3.39.2"
  gem "selenium-webdriver", "~> 4.15.0"
  gem "database_cleaner-active_record", "~> 2.1.0"
  gem "shoulda-matchers", "~> 6.0.0"
  gem "simplecov", "~> 0.22.0"
  gem "rails-controller-testing", "~> 1.0.5"
end

