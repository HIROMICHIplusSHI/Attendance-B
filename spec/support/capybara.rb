# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium-webdriver'

# Puma server設定（Rack 3対応）- リモートChrome用
Capybara.register_server :puma do |app, port, host|
  require 'rack/handler/puma'
  Rack::Handler::Puma.run(app, Host: host, Port: port, Threads: '0:4', workers: 0, daemon: false)
end

# Docker環境用のリモートChromeドライバの設定
Capybara.register_driver :remote_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV.fetch('SELENIUM_REMOTE_URL', 'http://chrome:4444/wd/hub'),
    options: options
  )
end

# JavaScript有効化用のドライバを設定
Capybara.javascript_driver = :remote_chrome

# デフォルト設定
Capybara.default_max_wait_time = 10  # Ajax待機時間（秒）
Capybara.default_normalize_ws = true  # 空白文字を正規化

# スクリーンショット保存設定
Capybara.save_path = Rails.root.join('tmp/screenshots')

# テスト失敗時にスクリーンショットを保存
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception && Capybara.current_driver != :rack_test
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"

      save_screenshot(screenshot_name)
      puts "\n  Screenshot saved: tmp/screenshots/#{screenshot_name}"
    end
  end
end
