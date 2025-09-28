require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }

  describe "GET /login" do
    it "ログインフォームが表示されること" do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    context "有効な認証情報の場合" do
      it "ログインに成功すること" do
        post login_path, params: { session: { email: user.email, password: "password" } }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "無効な認証情報の場合" do
      it "ログインに失敗すること" do
        post login_path, params: { session: { email: "invalid@example.com", password: "wrong" } }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("メールアドレスまたはパスワードが正しくありません")
      end
    end
  end

  describe "DELETE /logout" do
    it "ログアウトできること" do
      delete logout_path
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end
  end
end
