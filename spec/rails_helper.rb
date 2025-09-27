require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Capybara設定
Capybara.default_host = 'http://example.com'
Capybara.always_include_port = true

RSpec.configure do |config|
  config.fixture_paths = ["#{Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # システムテスト用のドライバー設定
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # RequestテストでCSRF保護を無効化
  config.before(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = false
  end

  config.after(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = true
  end
end
