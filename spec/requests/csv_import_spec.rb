require 'rails_helper'

RSpec.describe "CSVインポート", type: :request do
  let(:admin_user) do
    User.create!(
      name: "管理者",
      email: "admin@example.com",
      password: "password",
      role: :admin,
      employee_number: "A001",
      basic_time: Time.current.change(hour: 8, min: 0),
      work_time: Time.current.change(hour: 7, min: 30)
    )
  end

  let(:general_user) do
    User.create!(
      name: "一般ユーザー",
      email: "user@example.com",
      password: "password",
      role: :employee,
      employee_number: "E001",
      basic_time: Time.current.change(hour: 8, min: 0),
      work_time: Time.current.change(hour: 7, min: 30)
    )
  end

  let(:valid_csv) do
    Rack::Test::UploadedFile.new(
      StringIO.new(<<~CSV), 'text/csv', original_filename: 'users.csv'
        社員番号,氏名,メールアドレス,パスワード,役割,上長社員番号
        E100,山田太郎,yamada@example.com,password123,employee,
        M100,佐藤花子,sato@example.com,password123,manager,
        E101,鈴木一郎,suzuki@example.com,password123,employee,M100
      CSV
    )
  end

  describe "POST /users/import_csv" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password" } }
      end

      it "CSVファイルからユーザーを一括登録できる" do
        expect do
          post import_csv_users_path, params: { file: valid_csv }
        end.to change(User, :count).by(3)
      end

      it "社員番号が正しく登録される" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(User.find_by(employee_number: "E100")).to be_present
        expect(User.find_by(employee_number: "M100")).to be_present
      end

      it "役割が正しく登録される" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(User.find_by(employee_number: "E100").role).to eq("employee")
        expect(User.find_by(employee_number: "M100").role).to eq("manager")
      end

      it "基本時間と指定勤務時間にデフォルト値が設定される" do
        post import_csv_users_path, params: { file: valid_csv }
        user = User.find_by(employee_number: "E100")
        expect(user.basic_time.strftime("%H:%M")).to eq("08:00")
        expect(user.work_time.strftime("%H:%M")).to eq("07:30")
      end

      it "上長社員番号から上長を正しく関連付ける" do
        post import_csv_users_path, params: { file: valid_csv }
        manager = User.find_by(employee_number: "M100")
        employee = User.find_by(employee_number: "E101")
        expect(employee.manager_id).to eq(manager.id)
      end

      it "成功メッセージを表示する" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(flash[:success]).to include("3件のユーザーを登録しました")
      end

      it "ユーザー一覧ページにリダイレクトする" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(response).to redirect_to(users_path)
      end
    end

    context "バリデーションエラー時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password" } }
      end

      it "社員番号が重複している場合エラーメッセージを表示する" do
        User.create!(
          name: "既存ユーザー",
          email: "existing@example.com",
          password: "password",
          employee_number: "E100",
          basic_time: Time.current.change(hour: 8, min: 0),
          work_time: Time.current.change(hour: 7, min: 30)
        )

        post import_csv_users_path, params: { file: valid_csv }
        expect(flash[:danger]).to include("社員番号")
        expect(flash[:danger]).to include("すでに存在します")
      end

      it "メールアドレスが重複している場合エラーメッセージを表示する" do
        duplicate_csv = Rack::Test::UploadedFile.new(
          StringIO.new(<<~CSV), 'text/csv', original_filename: 'duplicate.csv'
            社員番号,氏名,メールアドレス,パスワード,役割,上長社員番号
            E200,テストユーザー,#{admin_user.email},password123,employee,
          CSV
        )

        post import_csv_users_path, params: { file: duplicate_csv }
        expect(flash[:danger]).to include("メールアドレス")
      end

      it "パスワードが6文字未満の場合エラーメッセージを表示する" do
        invalid_csv = Rack::Test::UploadedFile.new(
          StringIO.new(<<~CSV), 'text/csv', original_filename: 'invalid_password.csv'
            社員番号,氏名,メールアドレス,パスワード,役割,上長社員番号
            E300,テスト,test@example.com,pass,employee,
          CSV
        )

        post import_csv_users_path, params: { file: invalid_csv }
        expect(flash[:danger]).to include("パスワード")
      end

      it "役割が不正な値の場合エラーメッセージを表示する" do
        invalid_csv = Rack::Test::UploadedFile.new(
          StringIO.new(<<~CSV), 'text/csv', original_filename: 'invalid_role.csv'
            社員番号,氏名,メールアドレス,パスワード,役割,上長社員番号
            E400,テスト,test@example.com,password123,invalid_role,
          CSV
        )

        post import_csv_users_path, params: { file: invalid_csv }
        expect(flash[:danger]).to include("役割")
      end

      it "上長社員番号が存在しない場合エラーメッセージを表示する" do
        invalid_csv = Rack::Test::UploadedFile.new(
          StringIO.new(<<~CSV), 'text/csv', original_filename: 'invalid_manager.csv'
            社員番号,氏名,メールアドレス,パスワード,役割,上長社員番号
            E500,テスト,test@example.com,password123,employee,INVALID999
          CSV
        )

        post import_csv_users_path, params: { file: invalid_csv }
        expect(flash[:danger]).to include("上長")
        expect(flash[:danger]).to include("存在しません")
      end

      it "ファイルが選択されていない場合エラーメッセージを表示する" do
        post import_csv_users_path, params: { file: nil }
        expect(flash[:danger]).to eq("CSVファイルを選択してください")
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password" } }
      end

      it "アクセスできずルートパスにリダイレクトされる" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(response).to redirect_to(root_path)
      end

      it "権限エラーメッセージを表示する" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトされる" do
        post import_csv_users_path, params: { file: valid_csv }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
