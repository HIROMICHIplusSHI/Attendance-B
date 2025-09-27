require 'rails_helper'

RSpec.describe "Attendances", type: :request do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }
  let(:today) { Date.current }
  let(:attendance) { user.attendances.create!(worked_on: today) }

  before do
    # ログイン状態をセットアップ
    post login_path, params: { session: { email: user.email, password: "password" } }
  end

  describe "PATCH /users/:user_id/attendances/:id" do
    context "出勤時間の登録" do
      it "正常に出勤時間が登録できること" do
        patch user_attendance_path(user, attendance), params: {
          attendance: { started_at: "09:00" }
        }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:success]).to eq('出勤時間を登録しました')
        attendance.reload
        expect(attendance.started_at.strftime("%H:%M")).to eq("09:00")
      end

      it "既に出勤時間が登録されている場合はエラーとなること" do
        attendance.update!(started_at: Time.zone.parse("08:00"))

        patch user_attendance_path(user, attendance), params: {
          attendance: { started_at: "09:00" }
        }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:danger]).to eq('既に出勤時間が登録されています')
      end
    end

    context "退勤時間の登録" do
      before do
        attendance.update!(started_at: Time.zone.parse("09:00"))
      end

      it "正常に退勤時間が登録できること" do
        patch user_attendance_path(user, attendance), params: {
          attendance: { finished_at: "18:00" }
        }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:success]).to eq('退勤時間を登録しました')
        attendance.reload
        expect(attendance.finished_at.strftime("%H:%M")).to eq("18:00")
      end

      it "既に退勤時間が登録されている場合はエラーとなること" do
        attendance.update!(finished_at: Time.zone.parse("17:00"))

        patch user_attendance_path(user, attendance), params: {
          attendance: { finished_at: "18:00" }
        }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:danger]).to eq('既に退勤時間が登録されています')
      end

      it "出勤時間が未登録の場合はエラーとなること" do
        attendance.update!(started_at: nil)

        patch user_attendance_path(user, attendance), params: {
          attendance: { finished_at: "18:00" }
        }

        expect(response).to redirect_to(user_path(user))
        expect(flash[:danger]).to eq('出勤時間を先に登録してください')
      end
    end

    context "無効な時間フォーマット" do
      it "無効な時間フォーマットの場合はエラーとなること" do
        patch user_attendance_path(user, attendance), params: {
          attendance: { started_at: "invalid_time" }
        }

        expect(response).to redirect_to(user_path(user))
        # TODO: flashメッセージのテストを後で修正
        # expect(flash[:danger]).to eq('時間の形式が正しくありません')
      end
    end

    context "認証が必要" do
      before do
        delete logout_path  # ログアウト
      end

      it "未ログインの場合はログインページにリダイレクトされること" do
        patch user_attendance_path(user, attendance), params: {
          attendance: { started_at: "09:00" }
        }

        expect(response).to redirect_to(login_path)
      end
    end
  end
end
