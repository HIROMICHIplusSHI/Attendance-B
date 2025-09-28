require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "ユーザー登録ページが正常にアクセスできる" do
      get signup_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルに'新規登録'が含まれる" do
      get signup_path
      expect(response.body).to include('新規登録')
    end

    it "ユーザー登録フォームが表示される" do
      get signup_path
      expect(response.body).to include('form')
      expect(response.body).to include('name="user[name]"')
      expect(response.body).to include('name="user[email]"')
      expect(response.body).to include('name="user[password]"')
      expect(response.body).to include('name="user[password_confirmation]"')
    end

    it "登録ボタンが表示される" do
      get signup_path
      expect(response.body).to include('登録')
      expect(response.body).to include('btn btn-primary')
    end

    it "Bootstrap form-groupクラスが適用されている" do
      get signup_path
      expect(response.body).to include('form-group')
    end
  end

  describe "POST /users" do
    context "有効なパラメータの場合" do
      let(:valid_params) do
        {
          user: {
            name: "テストユーザー",
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "ユーザーが作成される" do
        expect do
          post users_path, params: valid_params
        end.to change(User, :count).by(1)
      end

      it "作成後にユーザー詳細ページにリダイレクトされる" do
        post users_path, params: valid_params
        user = User.last
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "無効なパラメータの場合" do
      let(:invalid_params) do
        {
          user: {
            name: "",
            email: "invalid_email",
            password: "short",
            password_confirmation: "different"
          }
        }
      end

      it "ユーザーが作成されない" do
        expect do
          post users_path, params: invalid_params
        end.not_to change(User, :count)
      end

      it "登録フォームが再表示される" do
        post users_path, params: invalid_params
        expect(response.body).to include('新規登録')
        expect(response.body).to include('form')
      end

      it "エラーメッセージが表示される" do
        post users_path, params: invalid_params
        expect(response.body).to include('error')
      end
    end
  end
end
