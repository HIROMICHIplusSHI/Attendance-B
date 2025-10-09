# frozen_string_literal: true

module SystemHelpers
  # ログインヘルパー
  def login_as(user)
    visit login_path
    fill_in 'session[email]', with: user.email
    fill_in 'session[password]', with: user.password
    click_button 'ログイン'
  end

  # モーダル待機
  def wait_for_modal
    expect(page).to have_css('.modal', visible: true)
  end

  # モーダルを閉じる
  def close_modal
    find('.modal .close').click
    expect(page).to have_css('.modal', visible: false)
  end

  # Ajax完了を待つ
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  private

  def finished_all_ajax_requests?
    page.evaluate_script('typeof jQuery !== "undefined" ? jQuery.active : 0').zero?
  rescue StandardError
    true
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
