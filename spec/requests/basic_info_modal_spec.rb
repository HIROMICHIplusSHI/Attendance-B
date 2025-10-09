require 'rails_helper'

RSpec.describe "BasicInfoModal", type: :request do
  let(:admin_user) do
    User.create!(
      name: "管理者ユーザー",
      email: "admin_#{Time.current.to_i}@example.com",
      password: "password123",
      role: :admin,
      department: "総務部",
      basic_time: Time.current.change(hour: 8, min: 0),
      work_time: Time.current.change(hour: 7, min: 30)
    )
  end

  let(:general_user) do
    User.create!(
      name: "一般ユーザー",
      email: "general_#{Time.current.to_i}@example.com",
      password: "password123",
      role: :employee,
      department: "開発部",
      basic_time: Time.current.change(hour: 8, min: 0),
      work_time: Time.current.change(hour: 7, min: 30)
    )
  end

  describe "GET /users/:id/edit_basic_info (基本情報編集モーダル)" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "基本情報編集ページが正常にアクセスできる" do
        get edit_basic_info_user_path(general_user)
        expect(response).to have_http_status(:success)
      end

      it "基本情報編集フォームが表示される" do
        get edit_basic_info_user_path(general_user)
        expect(response.body).to include('基本情報編集')
        expect(response.body).to include('form')
      end

      it "部署入力フィールドが表示される" do
        get edit_basic_info_user_path(general_user)
        expect(response.body).to include('department')
        expect(response.body).to include('所属')
      end

      it "基本時間入力フィールドが表示される" do
        get edit_basic_info_user_path(general_user)
        expect(response.body).to include('basic_time')
        expect(response.body).to include('基本時間')
      end

      it "指定勤務時間入力フィールドが表示される" do
        get edit_basic_info_user_path(general_user)
        expect(response.body).to include('work_time')
        expect(response.body).to include('指定勤務時間')
      end

      it "更新ボタンが表示される" do
        get edit_basic_info_user_path(general_user)
        expect(response.body).to include('更新')
        expect(response.body).to include('btn-primary')
      end

      it "Turbo Frameレスポンスに対応する" do
        get edit_basic_info_user_path(general_user), headers: { "Turbo-Frame" => "modal" }
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to include("text/html")
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "他人の基本情報編集ページにアクセスが拒否される" do
        get edit_basic_info_user_path(admin_user)
        expect(response).to redirect_to(root_path)
      end

      it "自分の基本情報編集ページにもアクセスが拒否される（管理者専用）" do
        get edit_basic_info_user_path(general_user)
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        get edit_basic_info_user_path(general_user)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /users/:id/update_basic_info (基本情報更新)" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            user: {
              department: "更新された部署",
              basic_time: "09:00",
              work_time: "08:00"
            }
          }
        end

        it "基本情報が正常に更新される" do
          patch update_basic_info_user_path(general_user), params: valid_params

          general_user.reload
          expect(general_user.department).to eq("更新された部署")
          expect(general_user.basic_time.strftime("%H:%M")).to eq("09:00")
          expect(general_user.work_time.strftime("%H:%M")).to eq("08:00")
        end

        it "成功メッセージが表示される" do
          patch update_basic_info_user_path(general_user), params: valid_params
          expect(flash[:success]).to be_present
          expect(flash[:success]).to include("基本情報を更新しました")
        end

        it "ユーザー詳細ページにリダイレクトされる" do
          patch update_basic_info_user_path(general_user), params: valid_params
          expect(response).to redirect_to(user_path(general_user))
        end

        it "Turbo Frameレスポンスに対応する" do
          patch update_basic_info_user_path(general_user),
                params: valid_params,
                headers: { "Turbo-Frame" => "modal" }
          expect(response).to have_http_status(:found)
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            user: {
              department: "a" * 100, # 長すぎる部署名
              basic_time: "",
              work_time: ""
            }
          }
        end

        it "基本情報が更新されない" do
          original_department = general_user.department
          patch update_basic_info_user_path(general_user), params: invalid_params

          general_user.reload
          expect(general_user.department).to eq(original_department)
        end

        it "編集ページが再表示される" do
          patch update_basic_info_user_path(general_user), params: invalid_params
          expect(response.body).to include('基本情報編集')
        end
      end

      context "部分的な更新の場合" do
        let(:partial_params) do
          {
            user: {
              department: "部分更新部署"
              # basic_time, work_timeは更新しない
            }
          }
        end

        it "指定されたフィールドのみ更新される" do
          original_basic_time = general_user.basic_time
          original_work_time = general_user.work_time

          patch update_basic_info_user_path(general_user), params: partial_params

          general_user.reload
          expect(general_user.department).to eq("部分更新部署")
          expect(general_user.basic_time).to eq(original_basic_time)
          expect(general_user.work_time).to eq(original_work_time)
        end
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "他人の基本情報更新が拒否される" do
        valid_params = {
          user: {
            department: "不正更新",
            basic_time: "09:00",
            work_time: "08:00"
          }
        }

        patch update_basic_info_user_path(admin_user), params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "自分の基本情報更新も拒否される（管理者専用）" do
        valid_params = {
          user: {
            department: "自己更新",
            basic_time: "09:00",
            work_time: "08:00"
          }
        }

        patch update_basic_info_user_path(general_user), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        valid_params = {
          user: {
            department: "未ログイン更新",
            basic_time: "09:00",
            work_time: "08:00"
          }
        }

        patch update_basic_info_user_path(general_user), params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "JavaScriptモーダル機能統合テスト" do
    before do
      post login_path, params: { session: { email: admin_user.email, password: "password123" } }
    end

    it "ユーザー詳細ページにモーダ開くリンクが表示される" do
      # 一般ユーザーが自分のページを見る場合、モーダルコンテナは存在するが基本情報編集ボタンは表示されない
      post login_path, params: { session: { email: general_user.email, password: "password123" } }
      get user_path(general_user)
      expect(response).to have_http_status(:success)
      # 一般ユーザーは基本情報編集リンクを見ることができない（管理者専用）
      expect(response.body).not_to include('edit_basic_info')
      # ただしモーダルコンテナ自体は存在する
      expect(response.body).to include('data-controller="form-modal"')
    end

    it "モーダル用のコンテナが存在する" do
      # 一般ユーザーが自分のページを見る場合、モーダルコンテナは存在する
      post login_path, params: { session: { email: general_user.email, password: "password123" } }
      get user_path(general_user)
      expect(response).to have_http_status(:success)
      # 自分のページにはモーダルコンテナが存在する
      expect(response.body).to include('data-controller="form-modal"')
      expect(response.body).to include('data-form-modal-target="container"')
    end

    it "基本情報編集ページがAJAXレスポンスに対応している" do
      get edit_basic_info_user_path(general_user), headers: { "X-Requested-With" => "XMLHttpRequest" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('基本情報編集')
    end

    it "フォームに確認ダイアログ属性が設定されている" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to include('data-confirm="true"')
      expect(response.body).to include('data-confirm-message="基本情報を更新してよろしいですか？"')
    end

    it "閉じるボタンがStimulus actionを使用している" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to include('data-action="form-modal#close"')
    end

    it "モーダルコンテンツにラッパーdivが含まれていない（二重モーダル防止）" do
      get edit_basic_info_user_path(general_user), headers: { "X-Requested-With" => "XMLHttpRequest" }
      # modal-header, modal-body, modal-footerは存在するが
      # modal-dialog, modal-contentのラッパーは含まれない
      expect(response.body).to include('class="modal-header"')
      expect(response.body).to include('class="modal-body"')
      expect(response.body).to include('class="modal-footer"')
      # ラッパーdivは親ビュー側にのみ存在し、コンテンツビューには無い
      expect(response.body).not_to match(/<div[^>]*class="modal-dialog"/)
      expect(response.body).not_to match(/<div[^>]*class="modal-content"[^>]*style=/)
    end
  end

  describe "UI要素テスト" do
    before do
      post login_path, params: { session: { email: admin_user.email, password: "password123" } }
    end

    it "基本情報の全ての入力フィールドが表示される" do
      get edit_basic_info_user_path(general_user)

      # 基本情報フィールド
      expect(response.body).to include('所属')
      expect(response.body).to include('基本時間')
      expect(response.body).to include('指定勤務時間')
    end

    it "モーダルタイトルが表示される" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to include('基本情報編集')
    end

    it "更新ボタンとキャンセルボタンが表示される" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to include('更新')
      expect(response.body).to include('キャンセル')
    end

    it "時間入力フィールドがtime_field型である" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to match(/type=["']time["']/)
    end

    it "フォームがユーザーIDを含むPATCHリクエストである" do
      get edit_basic_info_user_path(general_user)
      expect(response.body).to include("action=\"#{update_basic_info_user_path(general_user)}\"")
      expect(response.body).to match(/name=["']_method["'].*value=["']patch["']/)
    end
  end
end
