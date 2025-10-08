require 'rails_helper'

RSpec.describe OvertimeApprovalsController, type: :request do
  # ヘルパーメソッド: 勤怠データを作成
  def create_attendance_data(user, target_date = Date.today)
    user.attendances.create!(
      worked_on: target_date,
      started_at: Time.zone.parse("#{target_date} 09:00"),
      finished_at: Time.zone.parse("#{target_date} 18:00")
    )
  end

  let(:subordinate) do
    User.create!(
      name: "部下ユーザー",
      email: "subordinate_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部",
      basic_time: Time.zone.parse("2025-01-01 08:00"),
      work_time: Time.zone.parse("2025-01-01 08:00")
    )
  end

  let(:manager) do
    User.create!(
      name: "マネージャー",
      email: "manager_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部",
      role: :manager,
      basic_time: Time.zone.parse("2025-01-01 08:00"),
      work_time: Time.zone.parse("2025-01-01 08:00")
    ).tap do |user|
      subordinate.update!(manager_id: user.id)
    end
  end

  let(:regular_user) do
    User.create!(
      name: "一般ユーザー",
      email: "regular_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部",
      basic_time: Time.zone.parse("2025-01-01 08:00"),
      work_time: Time.zone.parse("2025-01-01 08:00")
    )
  end

  describe 'GET #index' do
    context 'マネージャーとしてログインしている場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: "password123" } }
      end

      it 'HTTPステータス200を返すこと' do
        get overtime_approvals_path
        expect(response).to have_http_status(:success)
      end

      it 'indexテンプレートを表示すること' do
        get overtime_approvals_path, xhr: true
        expect(response.body).to include('残業申請の承認')
      end

      it '自分が承認者となっている申請中の残業申請を取得すること' do
        # テストデータ作成
        user1 = User.create!(name: "申請者1", email: "user1_#{Time.current.to_i}@example.com", password: "password123")
        user2 = User.create!(name: "申請者2", email: "user2_#{Time.current.to_i}@example.com", password: "password123")
        user_for_approved = User.create!(name: "承認済申請者", email: "approved_#{Time.current.to_i}@example.com",
                                         password: "password123")

        # 勤怠データを作成
        create_attendance_data(user1)
        create_attendance_data(user2)
        create_attendance_data(user_for_approved)

        OvertimeRequest.create!(
          user: user1,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 22:00"),
          business_content: "システム開発",
          status: :pending
        )

        OvertimeRequest.create!(
          user: user2,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 21:00"),
          business_content: "緊急対応",
          status: :pending
        )

        OvertimeRequest.create!(
          user: user_for_approved,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 20:00"),
          business_content: "定例作業",
          status: :approved
        )

        get overtime_approvals_path, xhr: true

        # pendingの2件のみが表示されているか確認
        expect(OvertimeRequest.pending.where(approver: manager).count).to eq(2)
        expect(response.body).to include('申請者1')
        expect(response.body).to include('申請者2')
        expect(response.body).not_to include('承認済申請者')
      end

      it '他のマネージャー宛の残業申請は含まれないこと' do
        other_manager = User.create!(name: "他マネージャー", email: "other_mgr_#{Time.current.to_i}@example.com",
                                     password: "password123", role: :manager)
        user3 = User.create!(name: "申請者3", email: "user3_#{Time.current.to_i}@example.com", password: "password123")

        create_attendance_data(user3)

        OvertimeRequest.create!(
          user: user3,
          approver: other_manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 22:00"),
          business_content: "開発作業",
          status: :pending
        )

        get overtime_approvals_path, xhr: true

        expect(OvertimeRequest.pending.where(approver: manager).count).to eq(0)
        expect(response.body).not_to include('申請者3')
      end
    end

    context 'マネージャー権限がない場合' do
      before do
        post login_path, params: { session: { email: regular_user.email, password: "password123" } }
      end

      it 'ルートパスにリダイレクトすること' do
        get overtime_approvals_path
        expect(response).to redirect_to(root_path)
      end

      it 'アラートメッセージを表示すること' do
        get overtime_approvals_path
        expect(flash[:alert]).to eq('管理者権限が必要です')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトすること' do
        get overtime_approvals_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'PATCH #bulk_update' do
    context 'マネージャーとしてログインしている場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: "password123" } }
      end

      let!(:user1) do
        User.create!(name: "申請者1", email: "ap1_#{Time.current.to_i}@example.com", password: "password123")
      end
      let!(:user2) do
        User.create!(name: "申請者2", email: "ap2_#{Time.current.to_i}@example.com", password: "password123")
      end
      let!(:user3) do
        User.create!(name: "申請者3", email: "ap3_#{Time.current.to_i}@example.com", password: "password123")
      end

      let!(:attendance1) { create_attendance_data(user1) }
      let!(:attendance2) { create_attendance_data(user2) }
      let!(:attendance3) { create_attendance_data(user3) }

      let!(:request1) do
        OvertimeRequest.create!(
          user: user1,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 22:00"),
          business_content: "システム開発",
          status: :pending
        )
      end

      let!(:request2) do
        OvertimeRequest.create!(
          user: user2,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 21:00"),
          business_content: "緊急対応",
          status: :pending
        )
      end

      let!(:request3) do
        OvertimeRequest.create!(
          user: user3,
          approver: manager,
          worked_on: Date.today,
          estimated_end_time: Time.zone.parse("#{Date.today} 20:00"),
          business_content: "定例作業",
          status: :pending
        )
      end

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            requests: {
              request1.id.to_s => { selected: '1', status: 'approved' },
              request2.id.to_s => { selected: '1', status: 'rejected' },
              request3.id.to_s => { selected: '0', status: 'pending' }
            }
          }
        end

        it 'チェックされた残業申請のステータスを更新すること' do
          patch bulk_update_overtime_approvals_path, params: valid_params

          expect(request1.reload.status).to eq('approved')
          expect(request2.reload.status).to eq('rejected')
          expect(request3.reload.status).to eq('pending') # チェックなし
        end

        it 'ユーザー詳細ページにリダイレクトして成功メッセージを表示すること' do
          patch bulk_update_overtime_approvals_path, params: valid_params

          expect(response).to redirect_to(user_path(manager))
          expect(flash[:success]).to eq('承認処理が完了しました')
        end

        it '自分が承認者の申請のみ更新すること' do
          other_manager = User.create!(name: "他マネージャー", email: "othmgr_#{Time.current.to_i}@example.com",
                                       password: "password123", role: :manager)
          user4 = User.create!(name: "申請者4", email: "ap4_#{Time.current.to_i}@example.com", password: "password123")
          create_attendance_data(user4)

          other_request = OvertimeRequest.create!(
            user: user4,
            approver: other_manager,
            worked_on: Date.today,
            estimated_end_time: Time.zone.parse("#{Date.today} 22:00"),
            business_content: "開発作業",
            status: :pending
          )

          params = {
            requests: {
              other_request.id.to_s => { selected: '1', status: 'approved' }
            }
          }

          patch(bulk_update_overtime_approvals_path, params:)

          expect(other_request.reload.status).to eq('pending') # 変更されない
        end
      end

      context 'チェックされた項目がない場合' do
        let(:no_selection_params) do
          {
            requests: {
              request1.id.to_s => { selected: '0', status: 'approved' }
            }
          }
        end

        it 'アラートメッセージを表示してリダイレクトすること' do
          patch bulk_update_overtime_approvals_path, params: no_selection_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq('承認する項目を選択してください')
        end
      end

      context 'チェックされているが承認/否認が選択されていない場合' do
        let(:pending_status_params) do
          {
            requests: {
              request1.id.to_s => { selected: '1', status: 'pending' }
            }
          }
        end

        it 'アラートメッセージを表示してリダイレクトすること' do
          patch bulk_update_overtime_approvals_path, params: pending_status_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq('承認または否認を選択してください')
        end

        it 'ステータスが更新されないこと' do
          patch bulk_update_overtime_approvals_path, params: pending_status_params

          expect(request1.reload.status).to eq('pending')
        end
      end
    end

    context 'マネージャー権限がない場合' do
      before do
        post login_path, params: { session: { email: regular_user.email, password: "password123" } }
      end

      it 'ルートパスにリダイレクトすること' do
        patch bulk_update_overtime_approvals_path, params: { requests: {} }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
