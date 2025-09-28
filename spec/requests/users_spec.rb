require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:admin_user) do
    User.create!(name: "管理者ユーザー", email: "test_admin_#{Time.current.to_i}@example.com", password: "password123",
                 admin: true, department: "総務部",
                 basic_time: Time.current.change(hour: 8, min: 0),
                 work_time: Time.current.change(hour: 7, min: 30))
  end

  let(:general_user) do
    User.create!(name: "一般ユーザー", email: "test_general_#{Time.current.to_i}@example.com", password: "password123",
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
          timestamp = Time.current.to_i
          25.times do |i|
            User.create!(
              name: "ユーザー#{i + 1}",
              email: "pagination_user_#{i + 1}_#{timestamp}@example.com",
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
            email: "test_signup_#{Time.current.to_i}@example.com",
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

  describe "GET /users (ユーザー検索機能)" do
    let!(:test_users) do
      timestamp = Time.current.to_i
      [
        User.create!(name: "田中太郎", email: "test_tanaka_#{timestamp}@example.com", password: "password123",
                     admin: false, department: "営業部"),
        User.create!(name: "佐藤花子", email: "test_sato_#{timestamp}@example.com", password: "password123",
                     admin: false, department: "開発部"),
        User.create!(name: "田中次郎", email: "test_tanaka2_#{timestamp}@example.com", password: "password123",
                     admin: false, department: "総務部"),
        User.create!(name: "山田三郎", email: "test_yamada_#{timestamp}@example.com", password: "password123",
                     admin: false, department: "人事部")
      ]
    end

    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "検索フォームが表示される" do
        get users_path
        expect(response.body).to include('name="search"')
        expect(response.body).to include('検索')
      end

      it "部分一致検索で正しい結果が表示される" do
        get users_path, params: { search: "田中" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("田中太郎")
        expect(response.body).to include("田中次郎")
        expect(response.body).not_to include("佐藤花子")
        expect(response.body).not_to include("山田三郎")
      end

      it "検索結果が0件の場合も正常に表示される" do
        get users_path, params: { search: "存在しない名前" }
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("田中太郎")
        expect(response.body).not_to include("佐藤花子")
      end

      it "空の検索条件では全ユーザーが表示される" do
        get users_path, params: { search: "" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("田中太郎")
        expect(response.body).to include("佐藤花子")
      end

      it "検索条件がページネーション時に保持される" do
        # 20名以上のユーザーを作成してページネーション発生させる
        15.times do |i|
          User.create!(name: "田中テスト#{i}", email: "test_search_#{i}_#{Time.current.to_i}@example.com",
                       password: "password123", admin: false, department: "テスト部")
        end

        get users_path, params: { search: "田中", page: 1 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("田中")
        # 検索フォームに検索値が維持されていることを確認
        expect(response.body).to include('value="田中"')
      end

      it "検索結果もページネーションされる" do
        # 25名の田中さんを作成（一意なメールアドレス）
        25.times do |i|
          User.create!(name: "田中#{i}号", email: "tanaka_page_#{i}_#{Time.current.to_i}@example.com",
                       password: "password123", admin: false, department: "営業部")
        end

        get users_path, params: { search: "田中" }
        expect(response).to have_http_status(:success)
        # 20件制限でページネーションされることを確認
        tanaka_matches = response.body.scan(/<td><a[^>]*>田中/).length
        expect(tanaka_matches).to be <= 20
        expect(response.body).to include("次") # ページネーションボタンの存在確認
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "検索機能にアクセスできない" do
        get users_path, params: { search: "田中" }
        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end
  end
end
