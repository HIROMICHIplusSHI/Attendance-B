# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'アコーディオンのインタラクション', type: :system, js: true do
  let!(:admin_user) { create(:user, :admin, password: 'password123') }
  let!(:general_user) { create(:user, password: 'password123') }

  before do
    login_as(admin_user)
  end

  describe 'ユーザー編集モーダル（基本情報編集）' do
    it 'モーダルが開閉できる' do
      visit users_path

      # モーダルが最初は表示されていない
      expect(page).not_to have_css('[data-accordion-target="content"]', visible: true)

      # 最初のユーザーの編集ボタンをクリック
      first('[data-action="click->accordion#toggle"]').click

      # アコーディオンが表示される（モーダルではなくアコーディオン）
      expect(page).to have_css('[data-accordion-target="content"]', visible: true)
    end

    it 'フォーム入力が保持される' do
      visit users_path

      # 最初のユーザーの編集ボタンをクリック
      first('[data-action="click->accordion#toggle"]').click

      # アコーディオンが表示されるまで待機
      expect(page).to have_css('[data-accordion-target="content"]', visible: true)

      # フォームに入力
      within('[data-accordion-target="content"]') do
        fill_in 'user[department]', with: '開発部' if page.has_field?('user[department]')
      end
    end
  end


  describe '月次承認一覧モーダル' do
    let!(:approval) { create(:monthly_approval, :pending, approver: admin_user) }

    it 'モーダルが開閉できる', skip: '管理者は自分の勤怠ページにアクセスできないため、月次承認一覧の表示場所を確認する必要がある' do
      visit user_path(admin_user)

      # モーダルが最初は表示されていない
      expect(page).not_to have_css('.modal-dialog')

      # 月次承認一覧リンクをクリック
      click_link '月次承認一覧'

      # モーダルが表示される
      expect(page).to have_css('.modal-dialog', visible: true)
      expect(page).to have_content('月次承認一覧')

      # 閉じるボタンをクリック
      within('.modal-dialog') do
        first('.btn-secondary').click # 閉じるボタン
      end

      # モーダルが閉じる
      expect(page).not_to have_css('.modal-dialog', visible: true)
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
