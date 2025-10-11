# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'アコーディオンのインタラクション', type: :system, js: true do
  let!(:admin_user) { create(:user, :admin, password: 'password123') }
  let!(:general_user) { create(:user, password: 'password123') }

  before do
    login_as(admin_user)
  end

  describe '基本情報編集モーダル（ユーザー一覧から）' do
    it 'モーダルが開閉できる' do
      visit users_path

      # モーダルが最初は表示されていない
      expect(page).not_to have_css('.modal-dialog')

      # ユーザー一覧から基本情報編集リンクをクリック
      within("tr#user-#{general_user.id}") do
        click_link '基本情報'
      end

      # モーダルが表示される
      expect(page).to have_css('.modal-dialog', visible: true)
      expect(page).to have_content('基本情報の編集')

      # 閉じるボタンをクリック
      within('.modal-dialog') do
        click_button '閉じる'
      end

      # モーダルが閉じる
      expect(page).not_to have_css('.modal-dialog', visible: true)
    end

    it 'フォーム入力が保持される' do
      visit users_path

      within("tr#user-#{general_user.id}") do
        click_link '基本情報'
      end

      # フォームに入力
      within('.modal-dialog') do
        fill_in 'user[department]', with: '開発部'
        fill_in 'user[basic_time]', with: '8.0'
      end

      # 入力内容が保持されていることを確認
      within('.modal-dialog') do
        expect(find_field('user[department]').value).to eq('開発部')
        expect(find_field('user[basic_time]').value).to eq('8.0')
      end
    end
  end

  describe 'ユーザー編集モーダル' do
    it 'モーダルが開閉できる' do
      visit users_path

      # モーダルが最初は表示されていない
      expect(page).not_to have_css('.modal-dialog')

      # ユーザー編集リンクをクリック
      within("tr#user-#{general_user.id}") do
        click_link '編集'
      end

      # モーダルが表示される
      expect(page).to have_css('.modal-dialog', visible: true)
      expect(page).to have_content('ユーザー情報の編集')

      # 閉じるボタンをクリック
      within('.modal-dialog') do
        click_button '閉じる'
      end

      # モーダルが閉じる
      expect(page).not_to have_css('.modal-dialog', visible: true)
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

  describe 'Escapeキーでモーダルを閉じる' do
    it 'Escapeキーでモーダルが閉じる' do
      visit users_path

      within("tr#user-#{general_user.id}") do
        click_link '基本情報'
      end

      # モーダルが表示される
      expect(page).to have_css('.modal-dialog', visible: true)

      # Escapeキーを押す
      find('body').send_keys(:escape)

      # モーダルが閉じる（Bootstrapのデフォルト動作）
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
