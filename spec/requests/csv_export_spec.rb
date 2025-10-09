require 'rails_helper'

RSpec.describe 'CSV出力機能', type: :request do
  let(:user) { create(:user, role: :employee, name: '山田太郎') }
  let(:manager) { create(:user, role: :manager, name: '佐藤花子') }
  let(:admin) { create(:user, role: :admin, name: '管理者') }
  let(:other_user) { create(:user, role: :employee, name: '鈴木一郎') }
  let(:first_day) { Date.new(2025, 10, 1) }

  before do
    # 勤怠データ作成
    create(:attendance, user:, worked_on: first_day,
                        started_at: Time.zone.parse('2025-10-01 09:00'),
                        finished_at: Time.zone.parse('2025-10-01 18:00'))
    create(:attendance, user:, worked_on: first_day + 1,
                        started_at: Time.zone.parse('2025-10-02 09:15'),
                        finished_at: Time.zone.parse('2025-10-02 18:30'))
    create(:attendance, user:, worked_on: first_day + 2,
                        started_at: nil, finished_at: nil)
  end

  describe 'GET /users/:id/export_csv' do
    context '本人の場合' do
      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
      end

      it 'CSVをダウンロードできる' do
        get export_csv_user_path(user, date: first_day)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/csv')
      end

      it 'ファイル名が正しい（ユーザー名_YYYYMM_勤怠.csv）' do
        get export_csv_user_path(user, date: first_day)
        # Content-Dispositionヘッダーには日本語がURLエンコードされた形式で含まれる
        encoded_filename = '%E5%B1%B1%E7%94%B0%E5%A4%AA%E9%83%8E_202510_%E5%8B%A4%E6%80%A0.csv'
        expect(response.headers['Content-Disposition']).to include(encoded_filename)
      end

      it '表示月のデータのみ出力される' do
        # 別月のデータ作成
        create(:attendance, user:, worked_on: first_day.next_month,
                            started_at: Time.zone.parse('2025-11-01 09:00'),
                            finished_at: Time.zone.parse('2025-11-01 18:00'))

        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('2025/10/01')
        expect(csv_data).to include('2025/10/02')
        expect(csv_data).not_to include('2025/11/01')
      end

      it 'ヘッダー行が正しい' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')
        lines = csv_data.split("\n")

        expect(lines.first).to include('日付,曜日,出社時刻,退社時刻,在社時間,備考')
      end

      it '日付フォーマットがYYYY/MM/DD' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('2025/10/01')
      end

      it '時刻フォーマットがHH:MM' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('09:00')
        expect(csv_data).to include('18:00')
      end

      it '在社時間が正しく計算される' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('9.00')
      end

      it '曜日が正しく表示される' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        # 2025/10/01は水曜日
        expect(csv_data).to include('水')
      end
    end

    context 'pending状態の変更申請がある場合' do
      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
        create(:attendance_change_request,
               attendance: user.attendances.find_by(worked_on: first_day),
               requester: user,
               approver: manager,
               status: :pending)
      end

      it '該当する勤怠データが除外される' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')
        lines = csv_data.split("\n")

        # ヘッダー + 30行のデータ（10/01は除外、10/02〜10/31）
        expect(lines.count).to eq(31)
        expect(csv_data).not_to include('2025/10/01')
        expect(csv_data).to include('2025/10/02')
      end
    end

    context '承認済みの変更申請がある場合' do
      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
        create(:attendance_change_request,
               attendance: user.attendances.find_by(worked_on: first_day),
               requester: user,
               approver: manager,
               status: :approved)
      end

      it '該当する勤怠データが出力される' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('2025/10/01')
      end
    end

    context '否認済みの変更申請がある場合' do
      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
        create(:attendance_change_request,
               attendance: user.attendances.find_by(worked_on: first_day),
               requester: user,
               approver: manager,
               status: :rejected)
      end

      it '該当する勤怠データが出力される' do
        get export_csv_user_path(user, date: first_day)
        csv_data = response.body.force_encoding('UTF-8')

        expect(csv_data).to include('2025/10/01')
      end
    end

    context '上長の場合' do
      before do
        post login_path, params: { session: { email: manager.email, password: manager.password } }
      end

      xit '部下のCSVをダウンロードできる' do
        # TODO: manager_of_user?メソッドの実装が必要
        # manager_of_user?がtrueを返すように設定
        allow_any_instance_of(User).to receive(:manager_of_user?).and_return(true)

        get export_csv_user_path(user, date: first_day)
        expect(response).to have_http_status(:success)
      end
    end

    context '管理者の場合' do
      before do
        post login_path, params: { session: { email: admin.email, password: admin.password } }
      end

      it '全ユーザーのCSVをダウンロードできる' do
        get export_csv_user_path(user, date: first_day)
        expect(response).to have_http_status(:success)
      end
    end

    context '権限なしの場合' do
      before do
        post login_path, params: { session: { email: other_user.email, password: other_user.password } }
      end

      it 'アクセスできずリダイレクトされる' do
        get export_csv_user_path(user, date: first_day)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
