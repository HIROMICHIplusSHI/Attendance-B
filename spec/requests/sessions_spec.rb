require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }

  describe "GET /login" do
    it "ログインフォームが表示されること" do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ログイン")
    end

    it "RememberMeチェックボックスが表示されること" do
      get login_path
      expect(response.body).to include('name="session[remember_me]"')
      expect(response.body).to include("パスワードを記憶しますか？")
    end
  end

  describe "POST /login" do
    context "有効な認証情報の場合" do
      it "ログインに成功すること" do
        post login_path, params: { session: { email: user.email, password: "password" } }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(user_path(user))
      end

      context "管理者ユーザーの場合" do
        let(:admin) do
          User.create!(
            name: "管理者",
            email: "admin@example.com",
            password: "password",
            role: :admin,
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        it "ユーザー一覧ページにリダイレクトすること" do
          post login_path, params: { session: { email: admin.email, password: "password" } }
          expect(response).to redirect_to(users_path)
        end
      end

      context "一般ユーザーまたは上長の場合" do
        let(:employee) do
          User.create!(
            name: "社員",
            email: "employee@example.com",
            password: "password",
            role: :employee,
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        it "自分の勤怠ページにリダイレクトすること" do
          post login_path, params: { session: { email: employee.email, password: "password" } }
          expect(response).to redirect_to(user_path(employee))
        end
      end

      context "RememberMe機能" do
        it "remember_meがチェックされている場合、remember_tokenがCookieに設定されること" do
          post login_path, params: { session: { email: user.email, password: "password", remember_me: "1" } }
          expect(cookies[:remember_token]).not_to be_nil
        end

        it "remember_meがチェックされていない場合、remember_tokenがCookieに設定されないこと" do
          post login_path, params: { session: { email: user.email, password: "password", remember_me: "0" } }
          expect(cookies[:remember_token]).to be_nil
        end
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
