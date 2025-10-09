# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ユーザー基本フロー', type: :system do
  let(:user) { create(:user, password: 'password123') }
  let(:admin) { create(:user, :admin, password: 'password123') }

  describe 'ユーザーページ閲覧' do
    it 'ログイン後に自分のユーザーページを閲覧できる' do
      login_as(user)

      expect(page).to have_current_path(user_path(user))
      expect(page).to have_content(user.name)
      expect(page).to have_content('時間管理表')
    end

    it '管理者は他のユーザーページを閲覧できる' do
      login_as(admin)

      # 管理者はログイン後users_pathにリダイレクトされる
      expect(page).to have_current_path(users_path)

      visit user_path(user)

      expect(page).to have_current_path(user_path(user))
      expect(page).to have_content(user.name)
    end

    it '一般ユーザーは他人のページにアクセスできない' do
      other_user = create(:user)
      login_as(user)

      visit user_path(other_user)

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('アクセス権限がありません')
    end
  end

  describe 'ユーザー一覧' do
    it '管理者はユーザー一覧を閲覧できる' do
      login_as(admin)

      # 管理者はログイン後users_pathにリダイレクトされる
      expect(page).to have_current_path(users_path)
      expect(page).to have_content('ユーザー一覧')
    end

    it '一般ユーザーはユーザー一覧にアクセスできない' do
      login_as(user)

      visit users_path

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('管理者権限が必要です')
    end
  end
end
