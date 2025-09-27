require 'rails_helper'

RSpec.describe "ログインフロー", type: :system do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }

  describe "ログインフォーム" do
    it "正常にログインフォームが表示されること" do
      visit login_path

      expect(page).to have_content("ログイン")
      expect(page).to have_field("メールアドレス")
      expect(page).to have_field("パスワード")
      expect(page).to have_button("ログイン")
      expect(page).to have_link("アカウント作成", href: signup_path)
    end

    it "有効な情報でログインできること" do
      visit login_path

      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      click_button "ログイン"

      expect(page).to have_content("ログインしました")
      expect(current_path).to eq(user_path(user))
    end

    it "無効な情報でログインに失敗すること" do
      visit login_path

      fill_in "メールアドレス", with: "invalid@example.com"
      fill_in "パスワード", with: "wrongpassword"
      click_button "ログイン"

      expect(page).to have_content("メールアドレスまたはパスワードが正しくありません")
      expect(current_path).to eq(login_path)
    end

    it "空の情報でログインに失敗すること" do
      visit login_path

      click_button "ログイン"

      expect(page).to have_content("メールアドレスまたはパスワードが正しくありません")
      expect(current_path).to eq(login_path)
    end
  end

  describe "ログアウト機能" do
    it "ログイン後にログアウトできること" do
      # まずログイン
      visit login_path
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      click_button "ログイン"

      # ログアウト
      click_link "ログアウト"

      expect(page).to have_content("ログアウトしました")
      expect(current_path).to eq(root_path)
    end
  end
end
