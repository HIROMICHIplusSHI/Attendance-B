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
Capybara.default_host = 'http://localhost'
Capybara.always_include_port = true

# Support filesを読み込む
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = ["#{Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBotのメソッドをinclude
  config.include FactoryBot::Syntax::Methods

  # 各テスト前にデータベースをクリーンアップ
  config.before(:each) do
    AttendanceChangeRequest.delete_all
    OvertimeRequest.delete_all
    MonthlyApproval.delete_all
    Attendance.delete_all
    # manager_idの外部キー制約があるため、先にmanager_idをnullに設定
    User.update_all(manager_id: nil)
    User.delete_all
    Office.delete_all
  end

  # システムテスト用のドライバー設定
  config.before(:each, type: :system) do |example|
    if example.metadata[:js]
      # JavaScript有効なテストはリモートChromeを使用
      driven_by :remote_chrome
    else
      # JavaScript不要なテストはrack_testで高速実行
      driven_by :rack_test
    end
  end

  # RequestテストでCSRF保護を無効化とホスト設定
  config.before(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = false
    host! 'localhost'
  end

  config.after(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = true
  end
end
