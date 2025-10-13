require 'rails_helper'

RSpec.describe "Attendances", type: :request do
  let(:user) { User.create!(name: "テスト太郎", email: "test_#{Time.current.to_i}@example.com", password: "password") }
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
        delete logout_path # ログアウト
      end

      it "未ログインの場合はログインページにリダイレクトされること" do
        patch user_attendance_path(user, attendance), params: {
          attendance: { started_at: "09:00" }
        }

        expect(response).to redirect_to(login_path)
      end
    end
  end

  # 1ヶ月勤怠一括編集機能のテスト (feature/15)
  describe "1ヶ月勤怠一括編集機能" do
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

    before do
      # テスト用の勤怠データを作成
      current_month_start = Date.current.beginning_of_month
      current_month_end = Date.current.end_of_month

      (current_month_start..current_month_end).each do |date|
        general_user.attendances.create!(worked_on: date)
      end
    end

    describe "GET /users/:user_id/attendances/edit_one_month (1ヶ月勤怠一括編集ページ)" do
      context "管理者でログイン時" do
        before do
          post login_path, params: { session: { email: admin_user.email, password: "password123" } }
        end

        it "1ヶ月勤怠一括編集ページが正常にアクセスできる" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response).to have_http_status(:success)
        end

        it "ページタイトルに'1ヶ月の勤怠編集'が含まれる" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include('1ヶ月の勤怠編集')
        end

        it "現在の月の勤怠データが表示される" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include(general_user.name)
          expect(response.body).to include(Date.current.strftime("%Y年%m月"))
        end

        it "各日付の出勤・退勤時間入力フィールドが表示される" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include('started_at')
          expect(response.body).to include('finished_at')
          expect(response.body).to include('note')
        end

        it "フォームの送信ボタンが表示される" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include('勤怠変更申請を送信')
          expect(response.body).to include('form')
        end

        it "月ナビゲーション（前月・次月）リンクが表示される" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include('⇦')
          expect(response.body).to include('⇨')
        end

        it "戻るリンクが表示される" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response.body).to include('戻る')
        end
      end

      context "一般ユーザーでログイン時（自分の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "自分の1ヶ月勤怠一括編集ページにアクセスできる" do
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response).to have_http_status(:success)
        end
      end

      context "一般ユーザーでログイン時（他人の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "他人の1ヶ月勤怠一括編集ページにアクセスが拒否される" do
          get edit_one_month_user_attendances_path(admin_user, date: Date.current)
          expect(response).to redirect_to(root_path)
        end
      end

      context "未ログイン時" do
        it "ログインページにリダイレクトされる" do
          delete logout_path # ログアウト
          get edit_one_month_user_attendances_path(general_user, date: Date.current)
          expect(response).to redirect_to(login_path)
        end
      end
    end

    describe "PATCH /users/:user_id/attendances/update_one_month (1ヶ月勤怠変更申請)" do
      let!(:first_attendance) { general_user.attendances.find_by(worked_on: Date.current.beginning_of_month) }
      let!(:second_attendance) { general_user.attendances.find_by(worked_on: Date.current.beginning_of_month + 1.day) }
      let!(:manager_user) do
        User.create!(
          name: "上長ユーザー",
          email: "manager_#{Time.current.to_i}@example.com",
          password: "password123",
          role: :manager,
          department: "総務部",
          basic_time: Time.current.change(hour: 8, min: 0),
          work_time: Time.current.change(hour: 7, min: 30)
        )
      end

      before do
        # 既存の勤怠データに初期値を設定
        first_attendance.update!(started_at: Time.zone.parse("#{first_attendance.worked_on} 08:00"),
                                 finished_at: Time.zone.parse("#{first_attendance.worked_on} 17:00"))
        second_attendance.update!(started_at: Time.zone.parse("#{second_attendance.worked_on} 08:00"),
                                  finished_at: Time.zone.parse("#{second_attendance.worked_on} 17:00"))
      end

      context "管理者でログイン時" do
        before do
          post login_path, params: { session: { email: admin_user.email, password: "password123" } }
        end

        context "有効なパラメータの場合" do
          let(:valid_params) do
            {
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "18:00",
                  note: "電車遅延のため",
                  approver_id: manager_user.id
                },
                second_attendance.id.to_s => {
                  started_at: "10:00",
                  finished_at: "19:00",
                  note: "病院受診のため",
                  approver_id: manager_user.id
                }
              }
            }
          end

          it "AttendanceChangeRequestが2件作成される" do
            expect do
              patch update_one_month_user_attendances_path(general_user), params: valid_params
            end.to change(AttendanceChangeRequest, :count).by(2)
          end

          it "作成されたAttendanceChangeRequestの内容が正しい" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params

            request1 = AttendanceChangeRequest.find_by(attendance: first_attendance)
            expect(request1.requester).to eq(general_user)
            expect(request1.approver).to eq(manager_user)
            expect(request1.requested_started_at.strftime("%H:%M")).to eq("09:00")
            expect(request1.requested_finished_at.strftime("%H:%M")).to eq("18:00")
            expect(request1.change_reason).to eq("電車遅延のため")
            expect(request1.status).to eq("pending")
          end

          it "元の勤怠データは更新されない" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params

            first_attendance.reload
            expect(first_attendance.started_at.strftime("%H:%M")).to eq("08:00")
            expect(first_attendance.finished_at.strftime("%H:%M")).to eq("17:00")
          end

          it "成功メッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params
            expect(flash[:success]).to eq("2件の勤怠変更申請を送信しました")
          end

          it "ユーザー詳細ページにリダイレクトされる" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params
            expect(response).to redirect_to(user_path(general_user))
          end
        end

        context "承認者未選択の場合" do
          let(:no_approver_params) do
            {
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "18:00",
                  note: "変更理由"
                }
              }
            }
          end

          it "AttendanceChangeRequestが作成されない" do
            expect do
              patch update_one_month_user_attendances_path(general_user), params: no_approver_params
            end.not_to change(AttendanceChangeRequest, :count)
          end

          it "エラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: no_approver_params
            expect(flash[:danger]).to match(/の承認者を選択してください/)
          end

          it "編集ページが再表示される" do
            patch update_one_month_user_attendances_path(general_user), params: no_approver_params
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context "変更理由（備考）未入力の場合" do
          let(:no_reason_params) do
            {
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "18:00",
                  note: "", # 備考が空
                  approver_id: manager_user.id
                }
              }
            }
          end

          it "AttendanceChangeRequestが作成されない" do
            expect do
              patch update_one_month_user_attendances_path(general_user), params: no_reason_params
            end.not_to change(AttendanceChangeRequest, :count)
          end

          it "エラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: no_reason_params
            expect(flash[:danger]).to match(/変更理由（備考）を入力してください/)
          end

          it "編集ページが再表示される" do
            patch update_one_month_user_attendances_path(general_user), params: no_reason_params
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context "時間バリデーションの場合" do
          let(:invalid_time_params) do
            {
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "18:00",
                  finished_at: "09:00",
                  note: "時間エラー",
                  approver_id: manager_user.id
                }
              }
            }
          end

          it "出勤時間が退勤時間より遅い場合はエラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_time_params
            expect(flash[:danger]).to match(/出勤時間が退勤時間より遅いか同じ時間です/)
          end

          it "出勤時間が退勤時間より遅い場合はAttendanceChangeRequestが作成されない" do
            expect do
              patch update_one_month_user_attendances_path(general_user), params: invalid_time_params
            end.not_to change(AttendanceChangeRequest, :count)
          end

          it "出勤時間が退勤時間と同じ場合はエラーメッセージが表示される" do
            same_time_params = {
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "09:00",
                  note: "同じ時間エラー",
                  approver_id: manager_user.id
                }
              }
            }

            patch update_one_month_user_attendances_path(general_user), params: same_time_params
            expect(flash[:danger]).to match(/出勤時間が退勤時間より遅いか同じ時間です/)
          end

          it "編集ページが再表示される" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_time_params
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context "変更がない場合" do
          let(:no_change_params) do
            {
              approver_id: manager_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "08:00", # 既存と同じ
                  finished_at: "17:00", # 既存と同じ
                  note: "変更理由"
                }
              }
            }
          end

          it "AttendanceChangeRequestが作成されない" do
            expect do
              patch update_one_month_user_attendances_path(general_user), params: no_change_params
            end.not_to change(AttendanceChangeRequest, :count)
          end

          it "エラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: no_change_params
            expect(flash[:danger]).to eq("変更がありません。勤怠時間を変更してから申請してください。")
          end
        end

        context "フォーム値が保持される場合" do
          let(:error_params) do
            {
              approver_id: manager_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "18:00",
                  note: "" # エラーを引き起こす
                }
              }
            }
          end

          it "エラー時に編集ページが再表示される" do
            patch update_one_month_user_attendances_path(general_user), params: error_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("09:00")
            expect(response.body).to include("18:00")
          end
        end
      end

      context "一般ユーザーでログイン時（自分の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "自分の勤怠変更申請を送信できる" do
          valid_params = {
            attendances: {
              first_attendance.id.to_s => {
                started_at: "08:30",
                finished_at: "17:30",
                note: "自己申請",
                approver_id: manager_user.id
              }
            }
          }

          expect do
            patch update_one_month_user_attendances_path(general_user), params: valid_params
          end.to change(AttendanceChangeRequest, :count).by(1)

          expect(flash[:success]).to eq("1件の勤怠変更申請を送信しました")
        end
      end

      context "一般ユーザーでログイン時（他人の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "他人の勤怠変更申請が拒否される" do
          valid_params = {
            approver_id: manager_user.id,
            attendances: {
              "1" => {
                started_at: "09:00",
                finished_at: "18:00",
                note: "不正申請"
              }
            }
          }

          patch update_one_month_user_attendances_path(admin_user), params: valid_params
          expect(response).to redirect_to(root_path)
        end
      end

      context "未ログイン時" do
        it "ログインページにリダイレクトされる" do
          delete logout_path

          valid_params = {
            approver_id: manager_user.id,
            attendances: {
              first_attendance.id.to_s => {
                started_at: "09:00",
                finished_at: "18:00",
                note: "未ログイン"
              }
            }
          }

          patch update_one_month_user_attendances_path(general_user), params: valid_params
          expect(response).to redirect_to(login_path)
        end
      end
    end
  end
end
