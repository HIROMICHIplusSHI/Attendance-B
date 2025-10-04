# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "ApplicationRequests", type: :request do
  let(:user) do
    User.create!(name: "申請者", email: "user@example.com", password: "password", department: "開発部",
                 basic_time: Time.zone.parse("08:00"), work_time: Time.zone.parse("08:00"))
  end
  let(:approver) do
    User.create!(name: "承認者", email: "approver@example.com", password: "password", department: "管理部",
                 basic_time: Time.zone.parse("08:00"), work_time: Time.zone.parse("08:00"))
  end
  let(:attendance) do
    Attendance.create!(
      user:,
      worked_on: Date.current,
      started_at: Time.zone.parse("2025-01-01 09:00"),
      finished_at: Time.zone.parse("2025-01-01 18:00")
    )
  end

  before do
    post login_path, params: { session: { email: user.email, password: "password" } }
  end

  describe "POST /attendances/:attendance_id/application_requests" do
    context "勤怠変更のみ申請する場合" do
      it "AttendanceChangeRequestが作成されること" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              requested_started_at: "09:30",
              requested_finished_at: "18:30",
              change_reason: "電車遅延のため"
            }
          }
        end.to change(AttendanceChangeRequest, :count).by(1)
      end

      it "OvertimeRequestは作成されないこと" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              requested_started_at: "09:30",
              requested_finished_at: "18:30",
              change_reason: "電車遅延のため"
            }
          }
        end.not_to change(OvertimeRequest, :count)
      end

      it "成功メッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため"
          }
        }
        expect(flash[:success]).to eq "勤怠変更申請を送信しました"
      end

      it "ユーザー詳細ページにリダイレクトされること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため"
          }
        }
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "残業申請のみ申請する場合" do
      it "OvertimeRequestが作成されること" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              estimated_end_time: "22:00",
              business_content: "システム障害対応"
            }
          }
        end.to change(OvertimeRequest, :count).by(1)
      end

      it "AttendanceChangeRequestは作成されないこと" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              estimated_end_time: "22:00",
              business_content: "システム障害対応"
            }
          }
        end.not_to change(AttendanceChangeRequest, :count)
      end

      it "成功メッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            estimated_end_time: "22:00",
            business_content: "システム障害対応"
          }
        }
        expect(flash[:success]).to eq "残業申請を送信しました"
      end

      it "ユーザー詳細ページにリダイレクトされること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            estimated_end_time: "22:00",
            business_content: "システム障害対応"
          }
        }
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "勤怠変更と残業申請の両方を申請する場合" do
      it "AttendanceChangeRequestとOvertimeRequestの両方が作成されること" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              requested_started_at: "09:30",
              requested_finished_at: "18:30",
              change_reason: "電車遅延のため",
              estimated_end_time: "22:00",
              business_content: "システム障害対応"
            }
          }
        end.to change(AttendanceChangeRequest, :count).by(1)
           .and change(OvertimeRequest, :count).by(1)
      end

      it "成功メッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため",
            estimated_end_time: "22:00",
            business_content: "システム障害対応"
          }
        }
        expect(flash[:success]).to eq "勤怠変更と残業申請を送信しました"
      end

      it "ユーザー詳細ページにリダイレクトされること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため",
            estimated_end_time: "22:00",
            business_content: "システム障害対応"
          }
        }
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "両方とも入力がない場合" do
      it "エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id
          }
        }
        expect(flash[:danger]).to eq "勤怠変更か残業申請のいずれかを入力してください"
      end

      it "レコードが作成されないこと" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id
            }
          }
        end.not_to(change { AttendanceChangeRequest.count + OvertimeRequest.count })
      end
    end

    context "承認者が未選択の場合" do
      it "エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため"
          }
        }
        expect(flash[:danger]).to include "承認者を選択してください"
      end
    end

    context "勤怠変更申請が不完全な場合" do
      it "出勤時間のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30"
          }
        }
        expect(flash[:danger]).to include "勤怠変更申請は出勤時間、退勤時間、変更理由を全て入力してください"
      end

      it "退勤時間のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_finished_at: "18:30"
          }
        }
        expect(flash[:danger]).to include "勤怠変更申請は出勤時間、退勤時間、変更理由を全て入力してください"
      end

      it "変更理由のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            change_reason: "電車遅延のため"
          }
        }
        expect(flash[:danger]).to include "勤怠変更申請は出勤時間、退勤時間、変更理由を全て入力してください"
      end

      it "出勤時間と退勤時間のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30"
          }
        }
        expect(flash[:danger]).to include "勤怠変更申請は出勤時間、退勤時間、変更理由を全て入力してください"
      end

      it "レコードが作成されないこと" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              requested_started_at: "09:30"
            }
          }
        end.not_to change(AttendanceChangeRequest, :count)
      end
    end

    context "残業申請が不完全な場合" do
      it "終了予定時間のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            estimated_end_time: "22:00"
          }
        }
        expect(flash[:danger]).to include "残業申請は終了予定時間と業務内容を両方入力してください"
      end

      it "業務内容のみ入力時、エラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            business_content: "システム障害対応"
          }
        }
        expect(flash[:danger]).to include "残業申請は終了予定時間と業務内容を両方入力してください"
      end

      it "レコードが作成されないこと" do
        expect do
          post user_attendance_application_requests_path(user, attendance), params: {
            application_request: {
              approver_id: approver.id,
              estimated_end_time: "22:00"
            }
          }
        end.not_to change(OvertimeRequest, :count)
      end
    end

    context "勤怠変更が完全で残業申請が不完全な場合" do
      it "勤怠変更のみが作成され、残業申請のエラーメッセージが表示されること" do
        post user_attendance_application_requests_path(user, attendance), params: {
          application_request: {
            approver_id: approver.id,
            requested_started_at: "09:30",
            requested_finished_at: "18:30",
            change_reason: "電車遅延のため",
            estimated_end_time: "22:00"
          }
        }
        expect(flash[:danger]).to include "残業申請は終了予定時間と業務内容を両方入力してください"
      end
    end
  end
end
