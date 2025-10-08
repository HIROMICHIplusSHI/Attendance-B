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
          expect(response.body).to include('更新')
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

    describe "PATCH /users/:user_id/attendances/update_one_month (1ヶ月勤怠一括更新)" do
      let!(:first_attendance) { general_user.attendances.find_by(worked_on: Date.current.beginning_of_month) }
      let!(:second_attendance) { general_user.attendances.find_by(worked_on: Date.current.beginning_of_month + 1.day) }

      context "管理者でログイン時" do
        before do
          post login_path, params: { session: { email: admin_user.email, password: "password123" } }
        end

        context "有効なパラメータの場合" do
          let(:valid_params) do
            {
              user_id: general_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "18:00",
                  note: "通常勤務"
                },
                second_attendance.id.to_s => {
                  started_at: "10:00",
                  finished_at: "19:00",
                  note: "遅刻"
                }
              }
            }
          end

          it "勤怠データが一括更新される" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params

            first_attendance.reload
            second_attendance.reload

            expect(first_attendance.started_at.strftime("%H:%M")).to eq("09:00")
            expect(first_attendance.finished_at.strftime("%H:%M")).to eq("18:00")
            expect(first_attendance.note).to eq("通常勤務")

            expect(second_attendance.started_at.strftime("%H:%M")).to eq("10:00")
            expect(second_attendance.finished_at.strftime("%H:%M")).to eq("19:00")
            expect(second_attendance.note).to eq("遅刻")
          end

          it "成功メッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params
            expect(flash[:success]).to be_present
          end

          it "ユーザー詳細ページにリダイレクトされる" do
            patch update_one_month_user_attendances_path(general_user), params: valid_params
            expect(response).to redirect_to(user_path(general_user))
          end
        end

        context "無効なパラメータの場合" do
          let(:invalid_params) do
            {
              user_id: general_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "25:00", # 無効な時間
                  finished_at: "18:00",
                  note: "無効データ"
                }
              }
            }
          end

          it "勤怠データが更新されない" do
            original_started_at = first_attendance.started_at
            patch update_one_month_user_attendances_path(general_user), params: invalid_params

            first_attendance.reload
            expect(first_attendance.started_at).to eq(original_started_at)
          end

          it "エラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_params
            expect(flash[:danger]).to be_present
          end

          it "編集ページにリダイレクトされる" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_params
            expect(response).to redirect_to(edit_one_month_user_attendances_path(general_user))
          end
        end

        context "時間バリデーションの場合" do
          let(:invalid_time_params) do
            {
              user_id: general_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "18:00", # 出勤時間が退勤時間より遅い
                  finished_at: "09:00",
                  note: "時間エラー"
                }
              }
            }
          end

          it "出勤時間が退勤時間より遅い場合はエラーメッセージが表示される" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_time_params

            expect(flash[:danger]).to be_present
            expect(flash[:danger]).to match(/出勤時間が退勤時間より遅いか同じ時間です/)
          end

          it "出勤時間が退勤時間より遅い場合は勤怠データが更新されない" do
            original_started_at = first_attendance.started_at
            original_finished_at = first_attendance.finished_at

            patch update_one_month_user_attendances_path(general_user), params: invalid_time_params

            first_attendance.reload
            expect(first_attendance.started_at).to eq(original_started_at)
            expect(first_attendance.finished_at).to eq(original_finished_at)
          end

          it "出勤時間が退勤時間と同じ場合はエラーメッセージが表示される" do
            same_time_params = {
              user_id: general_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:00",
                  finished_at: "09:00", # 同じ時間
                  note: "同じ時間エラー"
                }
              }
            }

            patch update_one_month_user_attendances_path(general_user), params: same_time_params

            expect(flash[:danger]).to be_present
            expect(flash[:danger]).to match(/出勤時間が退勤時間より遅いか同じ時間です/)
          end

          it "時間バリデーションエラー時は編集ページにリダイレクトされる" do
            patch update_one_month_user_attendances_path(general_user), params: invalid_time_params

            expect(response).to redirect_to(edit_one_month_user_attendances_path(general_user))
          end
        end

        context "部分的な更新の場合" do
          let(:partial_params) do
            {
              user_id: general_user.id,
              attendances: {
                first_attendance.id.to_s => {
                  started_at: "09:30",
                  finished_at: "", # 空文字
                  note: "午前のみ"
                }
              }
            }
          end

          it "出勤時間のみ更新され、退勤時間は空のまま" do
            patch update_one_month_user_attendances_path(general_user), params: partial_params

            first_attendance.reload
            expect(first_attendance.started_at.strftime("%H:%M")).to eq("09:30")
            expect(first_attendance.finished_at).to be_nil
            expect(first_attendance.note).to eq("午前のみ")
          end
        end
      end

      context "一般ユーザーでログイン時（自分の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "自分の勤怠データを一括更新できる" do
          valid_params = {
            user_id: general_user.id,
            attendances: {
              first_attendance.id.to_s => {
                started_at: "08:30",
                finished_at: "17:30",
                note: "自己更新"
              }
            }
          }

          patch update_one_month_user_attendances_path(general_user), params: valid_params

          first_attendance.reload
          expect(first_attendance.started_at.strftime("%H:%M")).to eq("08:30")
          expect(first_attendance.note).to eq("自己更新")
        end
      end

      context "一般ユーザーでログイン時（他人の勤怠）" do
        before do
          post login_path, params: { session: { email: general_user.email, password: "password123" } }
        end

        it "他人の勤怠データ更新が拒否される" do
          valid_params = {
            user_id: admin_user.id,
            attendances: {
              "1" => {
                started_at: "09:00",
                finished_at: "18:00",
                note: "不正更新"
              }
            }
          }

          patch update_one_month_user_attendances_path(admin_user), params: valid_params
          expect(response).to redirect_to(root_path)
        end
      end

      context "未ログイン時" do
        it "ログインページにリダイレクトされる" do
          delete logout_path  # ログアウト

          valid_params = {
            user_id: general_user.id,
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
