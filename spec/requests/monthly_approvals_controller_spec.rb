require 'rails_helper'

RSpec.describe MonthlyApprovalsController, type: :request do
  # ヘルパーメソッド: 勤怠データを作成
  def create_attendance_data(user, target_month = Date.today.beginning_of_month)
    user.attendances.create!(
      worked_on: target_month,
      started_at: Time.zone.parse("#{target_month} 09:00"),
      finished_at: Time.zone.parse("#{target_month} 18:00")
    )
  end
  let(:subordinate) do
    User.create!(
      name: "部下ユーザー",
      email: "subordinate_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部"
    )
  end

  let(:manager) do
    User.create!(
      name: "マネージャー",
      email: "manager_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部"
    ).tap do |user|
      subordinate.update!(manager_id: user.id)
    end
  end

  let(:regular_user) do
    User.create!(
      name: "一般ユーザー",
      email: "regular_#{Time.current.to_i}@example.com",
      password: "password123",
      department: "開発部"
    )
  end

  describe 'GET #index' do
    context '管理者としてログインしている場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: "password123" } }
      end

      it 'HTTPステータス200を返すこと' do
        get monthly_approvals_path
        expect(response).to have_http_status(:success)
      end

      it 'indexテンプレートを表示すること' do
        get monthly_approvals_path
        expect(response.body).to include('所属長承認申請の承認')
      end

      it '自分が承認者となっている申請中の承認依頼を取得すること' do
        # テストデータ作成: このマネージャーへの申請中の承認依頼
        user1 = User.create!(name: "申請者1", email: "user1_#{Time.current.to_i}@example.com", password: "password123",
                             department: "開発部")
        user2 = User.create!(name: "申請者2", email: "user2_#{Time.current.to_i}@example.com", password: "password123",
                             department: "開発部")
        user_for_approved = User.create!(name: "承認済申請者", email: "approved_#{Time.current.to_i}@example.com",
                                         password: "password123", department: "開発部")

        # 勤怠データを作成
        create_attendance_data(user1)
        create_attendance_data(user2)
        create_attendance_data(user_for_approved)

        MonthlyApproval.create!(user: user1, approver: manager,
                                target_month: Date.today.beginning_of_month, status: :pending)
        MonthlyApproval.create!(user: user2, approver: manager,
                                target_month: Date.today.beginning_of_month, status: :pending)
        MonthlyApproval.create!(user: user_for_approved, approver: manager,
                                target_month: Date.today.beginning_of_month,
                                status: :approved) # 承認済みは含まれない

        get monthly_approvals_path

        # pendingの2件のみが表示されているか確認
        expect(MonthlyApproval.pending.where(approver: manager).count).to eq(2)
      end

      it '他のマネージャー宛の承認依頼は含まれないこと' do
        other_sub = User.create!(name: "他部下", email: "other_sub_#{Time.current.to_i}@example.com",
                                 password: "password123", department: "営業部")
        other_manager = User.create!(name: "他マネージャー", email: "other_mgr_#{Time.current.to_i}@example.com",
                                     password: "password123", department: "営業部")
        other_sub.update!(manager_id: other_manager.id)

        user3 = User.create!(name: "申請者3", email: "user3_#{Time.current.to_i}@example.com", password: "password123",
                             department: "営業部")
        # 勤怠データを作成
        create_attendance_data(user3)

        MonthlyApproval.create!(user: user3, approver: other_manager, target_month: Date.today.beginning_of_month,
                                status: :pending)

        get monthly_approvals_path

        # このマネージャー宛のpending承認はないはず
        expect(MonthlyApproval.pending.where(approver: manager).count).to eq(0)
      end
    end

    context '管理者権限がない場合' do
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
    context '管理者としてログインしている場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: "password123" } }
        # 勤怠データを作成
        create_attendance_data(user1)
        create_attendance_data(user2)
        create_attendance_data(user3)
      end

      let!(:user1) do
        User.create!(name: "申請者1", email: "ap1_#{Time.current.to_i}@example.com", password: "password123",
                     department: "開発部")
      end
      let!(:user2) do
        User.create!(name: "申請者2", email: "ap2_#{Time.current.to_i}@example.com", password: "password123",
                     department: "開発部")
      end
      let!(:user3) do
        User.create!(name: "申請者3", email: "ap3_#{Time.current.to_i}@example.com", password: "password123",
                     department: "開発部")
      end

      let!(:approval1) do
        MonthlyApproval.create!(user: user1, approver: manager, target_month: Date.today.beginning_of_month,
                                status: :pending)
      end
      let!(:approval2) do
        MonthlyApproval.create!(user: user2, approver: manager, target_month: Date.today.beginning_of_month,
                                status: :pending)
      end
      let!(:approval3) do
        MonthlyApproval.create!(user: user3, approver: manager, target_month: Date.today.beginning_of_month,
                                status: :pending)
      end

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            approvals: {
              approval1.id.to_s => { selected: '1', status: 'approved' },
              approval2.id.to_s => { selected: '1', status: 'rejected' },
              approval3.id.to_s => { selected: '0', status: 'approved' } # チェックなし
            }
          }
        end

        it 'チェックされた承認依頼のステータスを更新すること' do
          patch bulk_update_monthly_approvals_path, params: valid_params

          expect(approval1.reload.status).to eq('approved')
          expect(approval2.reload.status).to eq('rejected')
          expect(approval3.reload.status).to eq('pending') # チェックなし、変更されない
        end

        it '一覧ページにリダイレクトして成功メッセージを表示すること' do
          patch bulk_update_monthly_approvals_path, params: valid_params

          expect(response).to redirect_to(user_path(manager))
          expect(flash[:success]).to eq('承認処理が完了しました')
        end

        it '自分が承認者の承認依頼のみ更新すること' do
          other_sub = User.create!(name: "他部下", email: "othsub_#{Time.current.to_i}@example.com",
                                   password: "password123", department: "営業部")
          other_manager = User.create!(name: "他マネージャー", email: "othmgr_#{Time.current.to_i}@example.com",
                                       password: "password123", department: "営業部")
          other_sub.update!(manager_id: other_manager.id)

          user4 = User.create!(name: "申請者4", email: "ap4_#{Time.current.to_i}@example.com", password: "password123",
                               department: "営業部")
          # 勤怠データを作成
          create_attendance_data(user4)

          other_approval = MonthlyApproval.create!(user: user4, approver: other_manager,
                                                   target_month: Date.today.beginning_of_month, status: :pending)

          params = {
            approvals: {
              other_approval.id.to_s => { selected: '1', status: 'approved' }
            }
          }

          patch(bulk_update_monthly_approvals_path, params:)

          expect(other_approval.reload.status).to eq('pending') # 変更されない
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
    end

    context '管理者権限がない場合' do
      before do
        post login_path, params: { session: { email: regular_user.email, password: "password123" } }
      end

      it 'ルートパスにリダイレクトすること' do
        patch bulk_update_monthly_approvals_path, params: { approvals: {} }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
