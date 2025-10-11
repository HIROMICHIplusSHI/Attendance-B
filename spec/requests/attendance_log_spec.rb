require 'rails_helper'

RSpec.describe '勤怠ログ機能', type: :request do
  let(:user) { create(:user, role: :employee, name: '山田太郎') }
  let(:manager) { create(:user, role: :manager, name: '佐藤花子') }
  let(:admin) { create(:user, role: :admin, name: '管理者') }
  let(:other_user) { create(:user, role: :employee, name: '鈴木一郎') }
  let(:first_day) { Date.new(2025, 2, 1) }
  let(:attendance) do
    create(:attendance, user:, worked_on: first_day,
                        started_at: Time.zone.parse('2025-02-01 09:00'),
                        finished_at: Time.zone.parse('2025-02-01 18:00'))
  end

  before do
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  describe 'GET /users/:id/attendance_log' do
    context '承認済み変更申請が1件の場合' do
      before do
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'))
      end

      it '変更履歴が表示される' do
        get attendance_log_user_path(user, date: first_day)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('勤怠修正ログ')
      end

      it '変更前後の時刻が正しく表示される' do
        get attendance_log_user_path(user, date: first_day)
        expect(response.body).to include('10:00')
        expect(response.body).to include('18:00')
        expect(response.body).to include('11:00')
        expect(response.body).to include('19:00')
      end

      it '日付が表示される' do
        get attendance_log_user_path(user, date: first_day)
        expect(response.body).to include('02/01')
      end

      it '変更回数が1回目と表示される' do
        get attendance_log_user_path(user, date: first_day)
        expect(response.body).to include('1回目')
      end
    end

    context '同じ日付に複数回変更申請がある場合' do
      before do
        # 1回目の変更
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'),
               created_at: 1.day.ago)

        # 2回目の変更
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 11:00'),
               original_finished_at: Time.zone.parse('2025-02-01 19:00'),
               requested_started_at: Time.zone.parse('2025-02-01 12:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 20:00'),
               created_at: 12.hours.ago)

        # 3回目の変更
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 12:00'),
               original_finished_at: Time.zone.parse('2025-02-01 20:00'),
               requested_started_at: Time.zone.parse('2025-02-01 13:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 21:00'),
               created_at: 1.hour.ago)
      end

      it '全ての変更履歴がツリー状に表示される' do
        get attendance_log_user_path(user, date: first_day)

        # 1回目: 10:00-18:00 → 11:00-19:00
        expect(response.body).to include('1回目')
        expect(response.body).to include('10:00')
        expect(response.body).to include('18:00')
        expect(response.body).to include('11:00')
        expect(response.body).to include('19:00')

        # 2回目: 11:00-19:00 → 12:00-20:00
        expect(response.body).to include('2回目')
        expect(response.body).to include('12:00')
        expect(response.body).to include('20:00')

        # 3回目: 12:00-20:00 → 13:00-21:00
        expect(response.body).to include('3回目')
        expect(response.body).to include('13:00')
        expect(response.body).to include('21:00')
      end
    end

    context 'pending状態の変更申請がある場合' do
      before do
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :pending,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'))
      end

      it '表示されない' do
        get attendance_log_user_path(user, date: first_day)
        expect(response.body).to include('承認済みの変更履歴はありません')
      end
    end

    context 'rejected状態の変更申請がある場合' do
      before do
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :rejected,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'))
      end

      it '表示されない' do
        get attendance_log_user_path(user, date: first_day)
        expect(response.body).to include('承認済みの変更履歴はありません')
      end
    end

    context '管理者の場合' do
      before do
        post login_path, params: { session: { email: admin.email, password: admin.password } }
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'))
      end

      it '全ユーザーの勤怠ログを閲覧できる' do
        get attendance_log_user_path(user, date: first_day)
        expect(response).to have_http_status(:success)
      end
    end

    context '権限なしの場合' do
      before do
        post login_path, params: { session: { email: other_user.email, password: other_user.password } }
      end

      it 'アクセスできない（403 Forbidden）' do
        get attendance_log_user_path(user, date: first_day)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context '変更履歴が複数日ある場合' do
      let(:attendance2) do
        create(:attendance, user:, worked_on: first_day + 1,
                            started_at: Time.zone.parse('2025-02-02 09:00'),
                            finished_at: Time.zone.parse('2025-02-02 18:00'))
      end

      before do
        # 2/1の変更
        create(:attendance_change_request,
               attendance:,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-01 10:00'),
               original_finished_at: Time.zone.parse('2025-02-01 18:00'),
               requested_started_at: Time.zone.parse('2025-02-01 11:00'),
               requested_finished_at: Time.zone.parse('2025-02-01 19:00'))

        # 2/2の変更
        create(:attendance_change_request,
               attendance: attendance2,
               requester: user,
               approver: manager,
               status: :approved,
               original_started_at: Time.zone.parse('2025-02-02 09:00'),
               original_finished_at: Time.zone.parse('2025-02-02 17:00'),
               requested_started_at: Time.zone.parse('2025-02-02 09:30'),
               requested_finished_at: Time.zone.parse('2025-02-02 17:30'))
      end

      it '日付順にソートされて表示される' do
        get attendance_log_user_path(user, date: first_day)

        expect(response.body).to include('02/01')
        expect(response.body).to include('02/02')

        # 02/01が02/02より前に表示されることを確認
        index_feb01 = response.body.index('02/01')
        index_feb02 = response.body.index('02/02')
        expect(index_feb01).to be < index_feb02
      end
    end
  end
end
