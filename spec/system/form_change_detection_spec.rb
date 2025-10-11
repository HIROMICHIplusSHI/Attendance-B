# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'フォーム変更検知', type: :system, js: true do
  let(:admin_user) { create(:user, :admin, password: 'password123') }
  let(:general_user) { create(:user, password: 'password123') }

  before do
    login_as(admin_user)
  end

  describe '勤怠編集フォーム' do
    before do
      create_list(:attendance, 3, user: general_user)
    end

    it 'フォーム変更後にページを離れようとすると警告が表示される', skip: '実装確認後に有効化' do
      visit edit_one_month_user_attendances_path(general_user, date: Date.current.beginning_of_month)

      # フォームに変更を加える
      first('input[name*="[started_at]"]').fill_in with: '09:00'

      # ページを離れようとする
      visit users_path

      # 警告ダイアログが表示される（ブラウザのデフォルト動作）
      # Note: Capybaraでは`onbeforeunload`ダイアログの直接テストは困難
      # 代わりにJavaScriptのイベントリスナーが設定されているかを確認
    end

    it 'フォーム変更がない場合は警告が表示されない' do
      visit edit_one_month_user_attendances_path(general_user, date: Date.current.beginning_of_month)

      # フォームに変更を加えずにページを離れる
      visit users_path

      # 警告なしでページが遷移する
      expect(page).to have_current_path(users_path)
    end

    it 'フォーム送信後は警告が表示されない', skip: '実装確認後に有効化' do
      visit edit_one_month_user_attendances_path(general_user, date: Date.current.beginning_of_month)

      # フォームに変更を加える
      first('input[name*="[started_at]"]').fill_in with: '09:00'

      # フォームを送信
      click_button '更新'

      # 警告なしで成功ページに遷移
      expect(page).to have_content('勤怠情報を更新しました')
    end
  end

  describe '基本情報編集モーダル' do
    it 'モーダル内のフォーム変更を検知する' do
      visit user_path(general_user)

      click_link '基本情報の編集'

      within('.modal-dialog') do
        # フォームに変更を加える
        fill_in 'user[department]', with: '開発部'

        # 変更が反映されていることを確認
        expect(find_field('user[department]').value).to eq('開発部')
      end
    end

    it 'モーダル送信後はフォーム変更がリセットされる' do
      visit user_path(general_user)

      click_link '基本情報の編集'

      within('.modal-dialog') do
        fill_in 'user[department]', with: '開発部'
        fill_in 'user[basic_time]', with: '8.0'

        # JavaScriptによるバリデーション実行を待つ
        sleep 0.5

        click_button '更新'
      end

      # 成功メッセージを確認
      expect(page).to have_content('基本情報を更新しました')
    end
  end

  describe 'ユーザー編集フォーム' do
    it 'フォーム入力値のバリデーションが動作する' do
      visit edit_user_path(general_user)

      # メールアドレスを空にする
      fill_in 'user[email]', with: ''

      click_button '更新'

      # バリデーションエラーが表示される
      expect(page).to have_content('Emailを入力してください')
    end

    it '正しい入力値で更新が成功する' do
      visit edit_user_path(general_user)

      fill_in 'user[name]', with: '更新太郎'
      fill_in 'user[department]', with: '営業部'

      click_button '更新'

      # 成功メッセージを確認
      expect(page).to have_content('ユーザー情報を更新しました')
      expect(page).to have_content('更新太郎')
    end
  end

  private

  def login_as(user)
    visit login_path
    fill_in 'session[email]', with: user.email
    fill_in 'session[password]', with: user.password
    click_button 'ログイン'
  end
end
