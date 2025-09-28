require 'rails_helper'

RSpec.describe "UsersManagement", type: :request do
  let(:admin_user) { User.create!(name: "管理者", email: "admin@example.com", password: "password123", admin: true) }
  let(:regular_user) { User.create!(name: "一般ユーザー", email: "user@example.com", password: "password123") }
  let(:target_user) { User.create!(name: "対象ユーザー", email: "target@example.com", password: "password123") }

  describe "管理者の権限" do
    before do
      post login_path, params: { session: { email: admin_user.email, password: "password123" } }
    end

    it "ユーザー一覧にアクセスできる" do
      get users_path
      expect(response).to have_http_status(:success)
    end

    it "他のユーザーを編集できる" do
      get edit_user_path(target_user)
      expect(response).to have_http_status(:success)
    end

    it "他のユーザーを更新できる" do
      patch user_path(target_user), params: { user: { name: "更新された名前" } }
      expect(response).to redirect_to(target_user)
      expect(target_user.reload.name).to eq("更新された名前")
    end

    it "他のユーザーを削除できる" do
      delete user_path(target_user)
      expect(response).to redirect_to(users_path)
      expect(User.exists?(target_user.id)).to be_falsey
    end

    it "他のユーザーの基本情報を編集できる" do
      get edit_basic_info_user_path(target_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "一般ユーザーの権限" do
    before do
      post login_path, params: { session: { email: regular_user.email, password: "password123" } }
    end

    it "ユーザー一覧にアクセスできない" do
      get users_path
      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq("管理者権限が必要です。")
    end

    it "他のユーザーを編集できない" do
      get edit_user_path(target_user)
      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq("アクセス権限がありません。")
    end

    it "他のユーザーを更新できない" do
      patch user_path(target_user), params: { user: { name: "更新された名前" } }
      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq("アクセス権限がありません。")
    end

    it "他のユーザーを削除できない" do
      delete user_path(target_user)
      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq("管理者権限が必要です。")
    end

    it "自分のプロフィールは編集できる" do
      get edit_user_path(regular_user)
      expect(response).to have_http_status(:success)
    end

    it "自分の情報は更新できる" do
      patch user_path(regular_user), params: { user: { name: "更新された名前" } }
      expect(response).to redirect_to(regular_user)
      expect(regular_user.reload.name).to eq("更新された名前")
    end
  end

  describe "未ログイン時の権限" do
    it "ユーザー一覧にアクセスできない" do
      get users_path
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to eq("ログインしてください。")
    end

    it "ユーザー編集にアクセスできない" do
      get edit_user_path(target_user)
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to eq("ログインしてください。")
    end
  end
end
