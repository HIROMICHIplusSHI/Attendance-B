# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "MonthlyApprovals", type: :request do
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

  let(:target_month) { Date.current.beginning_of_month }

  describe 'GET #index' do
    context 'マネージャーとしてログインしている場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: "password123" } }
      end

      it 'HTTPステータス200を返すこと' do
        get monthly_approvals_path
        expect(response).to have_http_status(:success)
      end

      it 'indexテンプレートを表示すること' do
        get monthly_approvals_path, xhr: true
        expect(response.body).to include('所属長承認申請の承認')
      end

      it '自分が承認者となっている申請中の月次承認申請を取得すること' do
        user1 = User.create!(name: "申請者1", email: "user1_#{Time.current.to_i}@example.com", password: "password123")
        user2 = User.create!(name: "申請者2", email: "user2_#{Time.current.to_i}@example.com", password: "password123")
        user_for_approved = User.create!(name: "承認済申請者", email: "approved_#{Time.current.to_i}@example.com",
                                         password: "password123")

        # 勤怠データを作成
        create_attendance_data(user1, Date.current.beginning_of_month)
        create_attendance_data(user2, Date.current.beginning_of_month)
        create_attendance_data(user_for_approved, Date.current.beginning_of_month)

        MonthlyApproval.create!(
          user: user1,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )

        MonthlyApproval.create!(
          user: user2,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )

        MonthlyApproval.create!(
          user: user_for_approved,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :approved
        )

        get monthly_approvals_path, xhr: true

        expect(MonthlyApproval.pending.where(approver: manager).count).to eq(2)
        expect(response.body).to include('申請者1')
        expect(response.body).to include('申請者2')
        expect(response.body).not_to include('承認済申請者')
      end

      it '他のマネージャー宛の月次承認申請は含まれないこと' do
        other_manager = User.create!(name: "他マネージャー", email: "other_mgr_#{Time.current.to_i}@example.com",
                                     password: "password123")
        user3 = User.create!(name: "申請者3", email: "user3_#{Time.current.to_i}@example.com", password: "password123")

        create_attendance_data(user3, Date.current.beginning_of_month)

        MonthlyApproval.create!(
          user: user3,
          approver: other_manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )

        get monthly_approvals_path, xhr: true

        expect(MonthlyApproval.pending.where(approver: manager).count).to eq(0)
        expect(response.body).not_to include('申請者3')
      end
    end

    context 'マネージャー権限がない場合' do
      before do
        post login_path, params: { session: { email: regular_user.email, password: "password123" } }
      end

      it 'ルートパスにリダイレクトすること' do
        get monthly_approvals_path
        expect(response).to redirect_to(root_path)
      end

      it 'アラートメッセージを表示すること' do
        get monthly_approvals_path
        expect(flash[:alert]).to eq('管理者権限が必要です')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトすること' do
        get monthly_approvals_path
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
        User.create!(name: "申請者1", email: "ap1_#{Time.current.to_i}@example.com", password: "password123").tap do |u|
          create_attendance_data(u, Date.current.beginning_of_month)
        end
      end
      let!(:user2) do
        User.create!(name: "申請者2", email: "ap2_#{Time.current.to_i}@example.com", password: "password123").tap do |u|
          create_attendance_data(u, Date.current.beginning_of_month)
        end
      end
      let!(:user3) do
        User.create!(name: "申請者3", email: "ap3_#{Time.current.to_i}@example.com", password: "password123").tap do |u|
          create_attendance_data(u, Date.current.beginning_of_month)
        end
      end

      let!(:approval1) do
        MonthlyApproval.create!(
          user: user1,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )
      end

      let!(:approval2) do
        MonthlyApproval.create!(
          user: user2,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )
      end

      let!(:approval3) do
        MonthlyApproval.create!(
          user: user3,
          approver: manager,
          target_month: Date.current.beginning_of_month,
          status: :pending
        )
      end

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            approvals: {
              approval1.id.to_s => { selected: '1', status: 'approved' },
              approval2.id.to_s => { selected: '1', status: 'rejected' },
              approval3.id.to_s => { selected: '0', status: 'pending' }
            }
          }
        end

        it 'チェックされた月次承認申請のステータスを更新すること' do
          patch bulk_update_monthly_approvals_path, params: valid_params

          expect(approval1.reload.status).to eq('approved')
          expect(approval2.reload.status).to eq('rejected')
          expect(approval3.reload.status).to eq('pending')
        end

        it 'ユーザー詳細ページにリダイレクトして成功メッセージを表示すること' do
          patch bulk_update_monthly_approvals_path, params: valid_params

          expect(response).to redirect_to(user_path(manager))
          expect(flash[:success]).to eq('承認処理が完了しました')
        end

        it '自分が承認者の申請のみ更新すること' do
          other_manager = User.create!(name: "他マネージャー", email: "othmgr_#{Time.current.to_i}@example.com",
                                       password: "password123")
          user4 = User.create!(name: "申請者4", email: "ap4_#{Time.current.to_i}@example.com", password: "password123")
          create_attendance_data(user4, Date.current.beginning_of_month)

          other_approval = MonthlyApproval.create!(
            user: user4,
            approver: other_manager,
            target_month: Date.current.beginning_of_month,
            status: :pending
          )

          params = {
            approvals: {
              other_approval.id.to_s => { selected: '1', status: 'approved' }
            }
          }

          patch(bulk_update_monthly_approvals_path, params:)

          expect(other_approval.reload.status).to eq('pending')
        end
      end

      context 'チェックされた項目がない場合' do
        let(:no_selection_params) do
          {
            approvals: {
              approval1.id.to_s => { selected: '0', status: 'approved' }
            }
          }
        end

        it 'アラートメッセージを表示してリダイレクトすること' do
          patch bulk_update_monthly_approvals_path, params: no_selection_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq('承認する項目を選択してください')
        end
      end

      context 'チェックされているが承認/否認が選択されていない場合' do
        let(:pending_status_params) do
          {
            approvals: {
              approval1.id.to_s => { selected: '1', status: 'pending' }
            }
          }
        end

        it 'アラートメッセージを表示してリダイレクトすること' do
          patch bulk_update_monthly_approvals_path, params: pending_status_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash.now[:alert]).to eq('承認または否認を選択してください')
        end

        it 'ステータスが更新されないこと' do
          patch bulk_update_monthly_approvals_path, params: pending_status_params

          expect(approval1.reload.status).to eq('pending')
        end
      end
    end

    context 'マネージャー権限がない場合' do
      before do
        post login_path, params: { session: { email: regular_user.email, password: "password123" } }
      end

      it 'ルートパスにリダイレクトすること' do
        patch bulk_update_monthly_approvals_path, params: { approvals: {} }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /users/:user_id/monthly_approvals" do
    let(:user) do
      User.create!(name: "申請者", email: "user_#{Time.current.to_i}@example.com", password: "password")
    end
    let(:approver) do
      User.create!(name: "承認者", email: "approver_#{Time.current.to_i}@example.com", password: "password")
    end

    before do
      user.attendances.create!(
        worked_on: target_month,
        started_at: Time.zone.parse("#{target_month} 09:00"),
        finished_at: Time.zone.parse("#{target_month} 18:00")
      )
      post login_path, params: { session: { email: user.email, password: "password" } }
    end

    context "有効なパラメータの場合" do
      it "新しい月次承認申請が作成されること" do
        expect do
          post user_monthly_approvals_path(user), params: {
            monthly_approval: {
              approver_id: approver.id,
              target_month:
            }
          }
        end.to change(MonthlyApproval, :count).by(1)
      end

      it "ステータスがpendingに設定されること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.status).to eq 'pending'
      end

      it "成功メッセージが表示されること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(flash[:success]).to be_present
      end

      it "ユーザー詳細ページにリダイレクトされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(response).to redirect_to user_path(user)
      end
    end

    context "既存の申請がある場合（再承認）" do
      before do
        MonthlyApproval.create!(
          user:,
          approver:,
          target_month:,
          status: :approved,
          approved_at: Time.current
        )
      end

      it "既存レコードが上書きされること" do
        expect do
          post user_monthly_approvals_path(user), params: {
            monthly_approval: {
              approver_id: approver.id,
              target_month:
            }
          }
        end.not_to change(MonthlyApproval, :count)
      end

      it "ステータスがpendingにリセットされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.status).to eq 'pending'
      end

      it "approved_atがnilにリセットされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.approved_at).to be_nil
      end
    end
  end
end
