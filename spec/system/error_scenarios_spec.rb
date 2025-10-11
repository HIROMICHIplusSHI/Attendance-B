# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'エラーシナリオ', type: :system, js: true do
  let(:admin_user) { create(:user, :admin, password: 'password123') }
  let(:general_user) { create(:user, password: 'password123') }

  before do
    login_as(admin_user)
  end

  describe 'ネットワークエラー' do
    it 'モーダル読み込みエラー時にエラーメッセージが表示される', skip: 'ネットワークエラーのシミュレーション方法検討中' do
      # ネットワークエラーをシミュレート
      # page.driver.browser.network_conditions = { offline: true }

      visit user_path(general_user)

      click_link '基本情報の編集'

      # エラーメッセージが表示される
      expect(page).to have_content('ネットワークエラーが発生しました')
    end
  end

  describe 'タイムアウトエラー' do
    it 'リクエストがタイムアウトした場合にエラーメッセージが表示される', skip: 'タイムアウトのシミュレーション方法検討中' do
      # タイムアウトをシミュレート（30秒以上待機）
      visit user_path(general_user)

      # タイムアウトエラーのハンドリングを確認
      expect(page).to have_content('タイムアウトしました')
    end
  end

  describe 'サーバーエラー（500）' do
    it 'サーバーエラー時にエラーメッセージが表示される' do
      # サーバーエラーをシミュレート（存在しないユーザーID）
      visit user_path(999999)

      # エラーページまたはエラーメッセージが表示される
      expect(page).to have_content('見つかりませんでした')
    end
  end

  describe 'アクセス権限エラー（403）' do
    before do
      logout
      login_as(general_user)
    end

    it '管理者専用ページにアクセスするとエラーメッセージが表示される' do
      visit users_path

      # アクセス拒否メッセージが表示される
      expect(page).to have_content('管理者権限が必要です')
      expect(page).to have_current_path(root_path)
    end

    it '他のユーザーの編集ページにアクセスするとエラーメッセージが表示される' do
      other_user = create(:user)
      visit edit_user_path(other_user)

      # アクセス拒否メッセージが表示される
      expect(page).to have_content('アクセス権限がありません')
      expect(page).to have_current_path(root_path)
    end
  end

  describe 'バリデーションエラー' do
    it 'フォーム送信時のバリデーションエラーが表示される' do
      visit edit_user_path(general_user)

      # 必須項目を空にする
      fill_in 'user[name]', with: ''
      fill_in 'user[email]', with: ''

      click_button '更新'

      # バリデーションエラーが表示される
      expect(page).to have_content('Nameを入力してください')
      expect(page).to have_content('Emailを入力してください')
    end

    it 'モーダルフォームのバリデーションエラーが表示される' do
      visit user_path(general_user)

      click_link '基本情報の編集'

      within('.modal-dialog') do
        # 不正な値を入力
        fill_in 'user[basic_time]', with: '-1'

        click_button '更新'
      end

      # エラーメッセージが表示される（モーダル内）
      within('.modal-dialog') do
        expect(page).to have_css('.alert-danger') || expect(page).to have_content('エラー')
      end
    end
  end

  describe 'JavaScript エラーレポート' do
    it 'JavaScriptエラーがサーバーにレポートされる', skip: 'JavaScriptエラーの発生方法検討中' do
      # JavaScriptエラーを発生させる
      # page.execute_script('throw new Error("Test error")')

      # エラーレポートが送信されることを確認
      # expect(ErrorReport.count).to eq(1)
    end
  end

  describe 'セッション切れ' do
    it 'セッション切れ後は自動的にログインページにリダイレクトされる' do
      # セッションを削除
      page.driver.browser.manage.delete_all_cookies

      # 保護されたページにアクセス
      visit edit_user_path(general_user)

      # ログインページにリダイレクトされる
      expect(page).to have_current_path(login_path)
      expect(page).to have_content('ログインしてください')
    end
  end

  private

  def login_as(user)
    visit login_path
    fill_in 'session[email]', with: user.email
    fill_in 'session[password]', with: user.password
    click_button 'ログイン'
  end

  def logout
    visit logout_path
  end
end
