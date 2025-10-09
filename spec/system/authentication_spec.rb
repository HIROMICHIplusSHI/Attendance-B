# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '認証機能', type: :system do
  let(:user) { create(:user, password: 'password123') }

  describe 'ログイン' do
    context '正しい認証情報でログイン' do
      it 'ダッシュボードにリダイレクトされる' do
        visit login_path

        fill_in 'session[email]', with: user.email
        fill_in 'session[password]', with: 'password123'
        click_button 'ログイン'

        expect(page).to have_current_path(user_path(user))
        expect(page).to have_content(user.name)
      end
    end

    context '誤った認証情報でログイン' do
      it 'エラーメッセージが表示される' do
        visit login_path

        fill_in 'session[email]', with: user.email
        fill_in 'session[password]', with: 'wrong_password'
        click_button 'ログイン'

        expect(page).to have_current_path(login_path)
        expect(page).to have_content('メールアドレスまたはパスワードが正しくありません')
      end
    end
  end

  # ログアウトテストはJavaScript有効なテストで実装予定
  # describe 'ログアウト' do
  #   it 'ログアウトボタンからログアウトできる' do
  #     login_as(user)
  #
  #     # セッション削除によるログアウト（DELETEリクエスト）
  #     page.driver.submit :delete, logout_path, {}
  #
  #     visit root_path
  #     expect(page).to have_content('ログイン')
  #     expect(page).not_to have_content(user.name)
  #   end
  #
  #   it 'ログアウト後は保護されたページにアクセスできない' do
  #     login_as(user)
  #
  #     # セッション削除
  #     page.driver.submit :delete, logout_path, {}
  #
  #     # ログアウト後にユーザーページにアクセス
  #     visit user_path(user)
  #
  #     # ログインページにリダイレクトされる
  #     expect(page).to have_current_path(login_path)
  #     expect(page).to have_content('ログインしてください')
  #   end
  # end
end
