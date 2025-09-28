require 'rails_helper'

RSpec.describe "AdminPermissions", type: :request do
  let(:admin_user) do
    User.create!(name: "管理者ユーザー", email: "admin@example.com", password: "password123",
                 admin: true,
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  let(:general_user) do
    User.create!(name: "一般ユーザー", email: "user@example.com", password: "password123",
                 admin: false,
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  let(:other_user) do
    User.create!(name: "他のユーザー", email: "other@example.com", password: "password123",
                 admin: false,
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  describe "管理者権限チェック機能" do
    context "未ログイン時" do
      it "管理者専用ページにアクセスするとログインページにリダイレクトされる" do
        get users_path
        expect(response).to redirect_to(login_path)
      end

      it "他ユーザーの基本情報編集ページにアクセスするとログインページにリダイレクトされる" do
        get edit_basic_info_user_path(general_user)
        expect(response).to redirect_to(login_path)
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "管理者専用のユーザー一覧ページにアクセスできない" do
        get users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end

      it "他ユーザーの基本情報編集ページにアクセスできない" do
        get edit_basic_info_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end

      it "自分のプロフィールページにはアクセスできる" do
        get user_path(general_user)
        expect(response).to have_http_status(:success)
      end

      it "自分のプロフィール編集ページにはアクセスできる" do
        get edit_user_path(general_user)
        expect(response).to have_http_status(:success)
      end
    end

    context "管理者ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "ユーザー一覧ページにアクセスできる" do
        get users_path
        expect(response).to have_http_status(:success)
      end

      it "他ユーザーの基本情報編集ページにアクセスできる" do
        get edit_basic_info_user_path(general_user)
        expect(response).to have_http_status(:success)
      end

      it "他ユーザーのプロフィールページにアクセスできる" do
        get user_path(general_user)
        expect(response).to have_http_status(:success)
      end

      it "他ユーザーの1ヶ月勤怠編集ページにアクセスできる" do
        get edit_one_month_user_attendances_path(general_user)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "ApplicationControllerヘルパーメソッド" do
    let(:controller) { ApplicationController.new }

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    context "管理者ユーザーの場合" do
      let(:current_user) { admin_user }

      it "admin_or_correct_userが正しく動作する" do
        allow(controller).to receive(:params).and_return({ id: general_user.id.to_s })
        expect(controller.send(:admin_or_correct_user)).to be_truthy
      end
    end

    context "一般ユーザーの場合" do
      let(:current_user) { general_user }

      it "admin_or_correct_userが本人の場合のみtrueを返す" do
        allow(controller).to receive(:params).and_return({ id: general_user.id.to_s })
        expect(controller.send(:admin_or_correct_user)).to be_truthy

        allow(controller).to receive(:params).and_return({ id: other_user.id.to_s })
        expect(controller.send(:admin_or_correct_user)).to be_falsey
      end
    end

    context "未ログインユーザーの場合" do
      let(:current_user) { nil }

      it "admin_or_correct_userがfalseを返す" do
        allow(controller).to receive(:params).and_return({ id: general_user.id.to_s })
        expect(controller.send(:admin_or_correct_user)).to be_falsey
      end
    end
  end
end
