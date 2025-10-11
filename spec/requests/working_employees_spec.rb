require 'rails_helper'

RSpec.describe "WorkingEmployees", type: :request do
  let(:admin_user) do
    User.create!(
      name: "管理者",
      email: "admin_working_#{Time.current.to_i}@example.com",
      password: "password123",
      role: :admin,
      employee_number: "A001",
      department: "総務部"
    )
  end

  let(:general_user) do
    User.create!(
      name: "一般ユーザー",
      email: "general_working_#{Time.current.to_i}@example.com",
      password: "password123",
      role: :employee,
      employee_number: "E001",
      department: "開発部",
      basic_time: Time.zone.parse("2025-01-01 08:00"),
      work_time: Time.zone.parse("2025-01-01 08:00")
    )
  end

  describe "GET /working_employees" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: "password123" } }
      end

      it "HTTPステータス200を返すこと" do
        get working_employees_path
        expect(response).to have_http_status(:success)
      end

      context "出勤データがある場合" do
        let!(:employee1) do
          User.create!(
            name: "出勤社員1",
            email: "working1_#{Time.current.to_i}@example.com",
            password: "password123",
            role: :employee,
            employee_number: "E100",
            department: "営業部",
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        let!(:employee2) do
          User.create!(
            name: "出勤社員2",
            email: "working2_#{Time.current.to_i}@example.com",
            password: "password123",
            role: :employee,
            employee_number: "E050",
            department: "開発部",
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        let!(:employee3) do
          User.create!(
            name: "退勤済み社員",
            email: "left_#{Time.current.to_i}@example.com",
            password: "password123",
            role: :employee,
            employee_number: "E200",
            department: "人事部",
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        let!(:employee4) do
          User.create!(
            name: "未出勤社員",
            email: "absent_#{Time.current.to_i}@example.com",
            password: "password123",
            role: :employee,
            employee_number: "E300",
            department: "総務部",
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        before do
          # 出勤中（出社済み・未退勤）
          employee1.attendances.create!(
            worked_on: Date.today,
            started_at: Time.zone.parse("#{Date.today} 09:00")
          )

          employee2.attendances.create!(
            worked_on: Date.today,
            started_at: Time.zone.parse("#{Date.today} 08:30")
          )

          # 退勤済み
          employee3.attendances.create!(
            worked_on: Date.today,
            started_at: Time.zone.parse("#{Date.today} 09:00"),
            finished_at: Time.zone.parse("#{Date.today} 18:00")
          )

          # 未出勤
          employee4.attendances.create!(
            worked_on: Date.today
          )
        end

        it "本日出勤中の社員のみ取得すること" do
          get working_employees_path
          expect(response.body).to include("出勤社員1")
          expect(response.body).to include("出勤社員2")
        end

        it "退勤済み社員は含まれないこと" do
          get working_employees_path
          expect(response.body).not_to include("退勤済み社員")
        end

        it "未出勤社員は含まれないこと" do
          get working_employees_path
          expect(response.body).not_to include("未出勤社員")
        end

        it "社員番号順にソートされること" do
          get working_employees_path
          # E050が先、E100が後
          body = response.body
          index_e050 = body.index("E050")
          index_e100 = body.index("E100")
          expect(index_e050).to be < index_e100
        end

        it "出勤中社員の件数が表示されること" do
          get working_employees_path
          expect(response.body).to include("2名")
        end
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: "password123" } }
      end

      it "ルートパスにリダイレクトすること" do
        get working_employees_path
        expect(response).to redirect_to(root_path)
      end

      it "アラートメッセージを表示すること" do
        get working_employees_path
        expect(flash[:danger]).to eq("管理者権限が必要です。")
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトすること" do
        get working_employees_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
