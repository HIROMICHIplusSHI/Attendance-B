require 'rails_helper'

RSpec.describe "HeaderNavigation", type: :request do
  let(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123") }

  describe "未ログイン時のヘッダー" do
    it "navbar-fixed-top navbar-inverseクラスが適用されている" do
      get root_path
      expect(response.body).to include('navbar navbar-fixed-top navbar-inverse')
    end

    it "Attendance Appロゴが表示される" do
      get root_path
      expect(response.body).to include('Attendance App')
      expect(response.body).to include('id="logo"')
    end

    it "トップリンクが表示される" do
      get root_path
      expect(response.body).to include('トップ')
      expect(response.body).to include('href="/"')
    end

    it "ログインリンクが表示される" do
      get root_path
      # ヘッダー部分のナビゲーションにログインリンクが含まれていることを確認
      nav_section = response.body.match(%r{<nav>.*?</nav>}m)&.to_s || ""
      expect(nav_section).to include('ログイン')
      expect(nav_section).to include('href="/login"')
    end

    it "ドロップダウンメニューが表示されない" do
      get root_path
      expect(response.body).not_to include('dropdown')
    end
  end

  describe "ログイン時のヘッダー" do
    before do
      # セッションに直接ユーザーIDを設定してログイン状態をシミュレート
      post login_path, params: { session: { email: user.email, password: "password123" } }
      follow_redirect! if response.redirect?
    end

    it "ユーザー名がナビゲーションに表示される" do
      get root_path
      expect(response.body).to include(user.name)
    end

    it "ドロップダウンメニューが表示される" do
      get root_path
      expect(response.body).to include('dropdown')
      expect(response.body).to include('dropdown-toggle')
    end

    it "プロフィールリンクが表示される" do
      get root_path
      expect(response.body).to include('プロフィール')
      expect(response.body).to include("href=\"/users/#{user.id}\"")
    end

    # ユーザー一覧は管理者権限が必要なため、現段階では実装しない

    it "設定リンクが表示される" do
      get root_path
      expect(response.body).to include('設定')
      expect(response.body).to include("href=\"/users/#{user.id}/edit\"")
    end

    it "ログアウトリンクが表示される" do
      get root_path
      expect(response.body).to include('ログアウト')
      expect(response.body).to include('href="/logout"')
      expect(response.body).to include('data-turbo-method="delete"')
    end

    it "ログインリンクが表示されない" do
      get root_path
      # ヘッダー部分のナビゲーションにログインリンクが含まれていないことを確認
      # topページのメインコンテンツのログインボタンは除外する
      nav_section = response.body.match(%r{<nav>.*?</nav>}m)&.to_s || ""
      expect(nav_section).not_to include('href="/login"')
    end
  end

  describe "管理者ログイン時のヘッダー" do
    let(:admin_user) { User.create!(name: "管理者", email: "admin@example.com", password: "password123", admin: true) }

    before do
      post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      follow_redirect! if response.redirect?
    end

    it "管理者メニューが表示される" do
      get root_path
      expect(response.body).to include('管理者メニュー')
      expect(response.body).to include('dropdown-header')
    end

    it "ユーザー一覧リンクが表示される" do
      get root_path
      expect(response.body).to include('ユーザー一覧')
      expect(response.body).to include('href="/users"')
    end

    it "基本設定の修正リンクが表示される" do
      get root_path
      expect(response.body).to include('基本設定の修正')
      expect(response.body).to include("href=\"/users/#{admin_user.id}/edit_basic_info\"")
    end
  end

  describe "一般ユーザーログイン時のヘッダー" do
    before do
      post login_path, params: { session: { email: user.email, password: "password123" } }
      follow_redirect! if response.redirect?
    end

    it "管理者メニューが表示されない" do
      get root_path
      expect(response.body).not_to include('管理者メニュー')
      expect(response.body).not_to include('ユーザー一覧')
      expect(response.body).not_to include('基本設定の修正')
    end
  end

  describe "JavaScript機能" do
    it "ドロップダウントグル用のクラスが含まれる" do
      post login_path, params: { session: { email: user.email, password: "password123" } }
      follow_redirect! if response.redirect?
      get root_path
      expect(response.body).to include('dropdown-toggle')
      expect(response.body).to include('dropdown-menu')
    end
  end
end
