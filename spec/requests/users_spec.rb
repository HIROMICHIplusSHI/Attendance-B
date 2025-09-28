require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:admin_user) do
    User.create!(name: "管理者ユーザー", email: "admin@example.com", password: "password123",
                 admin: true, department: "総務部",
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  let(:general_user) do
    User.create!(name: "一般ユーザー", email: "user@example.com", password: "password123",
                 admin: false, department: "開発部",
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  describe "GET /users (ユーザー一覧)" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "ユーザー一覧ページが正常にアクセスできる" do
        get users_path
        expect(response).to have_http_status(:success)
      end

      it "ユーザー一覧が表示される" do
        general_user # ensure general_user is created
        get users_path
        expect(response.body).to include(admin_user.name)
        expect(response.body).to include(general_user.name)
      end

      it "部署情報が表示される" do
        general_user # ensure general_user is created
        get users_path
        expect(response.body).to include(admin_user.department)
        expect(response.body).to include(general_user.department)
      end

      it "削除リンクが表示される" do
        get users_path
        expect(response.body).to include("削除")
      end

      context "21人以上のユーザーがいる場合" do
        before do
          25.times do |i|
            User.create!(
              name: "ユーザー#{i + 1}",
              email: "user#{i + 1}@example.com",
              password: "password123",
              department: "部署#{(i % 3) + 1}"
            )
          end
        end

        it "ページネーションが表示される" do
          get users_path
          expect(response.body).to include("次")
          expect(response.body).to include("前")
        end

        it "20件のユーザーのみ表示される" do
          get users_path
          user_names = response.body.scan(/ユーザー\d+/).uniq
          expect(user_names.count).to be <= 20
        end
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "アクセスが拒否される" do
        get users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        get users_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
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
