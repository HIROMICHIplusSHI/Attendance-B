require 'rails_helper'

RSpec.describe "ユーザー登録フロー", type: :system do
  describe "ユーザー登録フォーム" do
    it "正常にユーザー登録フォームが表示されること" do
      visit signup_path

      expect(page).to have_content("新規登録")
      expect(page).to have_field("名前")
      expect(page).to have_field("メールアドレス")
      expect(page).to have_field("パスワード")
      expect(page).to have_field("パスワード確認")
      expect(page).to have_button("登録")
    end

    it "有効な情報でユーザー登録できること" do
      visit signup_path

      fill_in "名前", with: "テスト太郎"
      fill_in "メールアドレス", with: "test@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード確認", with: "password123"
      click_button "登録"

      expect(page).to have_content("アカウント作成が完了しました")
      expect(current_path).to match(%r{/users/\d+})
    end

    it "無効な情報でユーザー登録に失敗すること" do
      visit signup_path

      fill_in "名前", with: ""
      fill_in "メールアドレス", with: "invalid_email"
      fill_in "パスワード", with: "short"
      fill_in "パスワード確認", with: "different"
      click_button "登録"

      expect(page).to have_content("エラーが発生しました")
      expect(current_path).to eq(users_path)
    end

    it "既存メールアドレスでユーザー登録に失敗すること" do
      # 既存ユーザー作成
      User.create!(name: "既存ユーザー", email: "existing@example.com", password: "password123")

      visit signup_path

      fill_in "名前", with: "新規ユーザー"
      fill_in "メールアドレス", with: "existing@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード確認", with: "password123"
      click_button "登録"

      expect(page).to have_content("エラーが発生しました")
      expect(current_path).to eq(users_path)
    end
  end
end
