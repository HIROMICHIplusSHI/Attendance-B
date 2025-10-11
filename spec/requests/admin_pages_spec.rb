require 'rails_helper'

RSpec.describe "AdminPages", type: :request do
  let(:admin_user) do
    User.create!(name: "管理者ユーザー", email: "admin@example.com", password: "password123",
                 role: :admin,
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  let(:general_user) do
    User.create!(name: "一般ユーザー", email: "user@example.com", password: "password123",
                 role: :employee,
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  describe "出勤社員一覧ページ" do
    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        get working_employees_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "アクセスできず、ルートパスにリダイレクトされる" do
        get working_employees_path
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "管理者ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "アクセスできる" do
        get working_employees_path
        expect(response).to have_http_status(:success)
      end

      it "「出勤社員一覧」タイトルが表示される" do
        get working_employees_path
        expect(response.body).to include("出勤社員一覧")
      end
    end
  end

  describe "拠点情報修正ページ" do
    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        get offices_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "アクセスできず、ルートパスにリダイレクトされる" do
        get offices_path
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "管理者ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "アクセスできる" do
        get offices_path
        expect(response).to have_http_status(:success)
      end

      it "「拠点情報修正」タイトルが表示される" do
        get offices_path
        expect(response.body).to include("拠点情報修正")
      end
    end
  end

  describe "基本情報の修正ページ" do
    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        get basic_info_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "アクセスできず、ルートパスにリダイレクトされる" do
        get basic_info_path
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "管理者ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "アクセスできる" do
        get basic_info_path
        expect(response).to have_http_status(:success)
      end

      it "「基本情報の修正」タイトルが表示される" do
        get basic_info_path
        expect(response.body).to include("基本情報の修正")
      end
    end
  end
end
