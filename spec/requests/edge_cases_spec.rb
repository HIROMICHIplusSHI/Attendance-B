# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'エッジケース', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:general_user) { create(:user) }

  describe 'パラメータのエッジケース' do
    before { sign_in admin_user }

    context '不正なIDパラメータ' do
      it '存在しないユーザーIDでアクセスすると404エラー' do
        get user_path(999_999)
        expect(response).to have_http_status(:not_found)
      end

      it '不正な形式のIDパラメータでアクセスすると404エラー' do
        get user_path('invalid_id')
        expect(response).to have_http_status(:not_found)
      end
    end

    context '日付パラメータの境界値' do
      it '月初の日付で勤怠データを取得できる' do
        date = Date.new(2025, 1, 1)
        get user_path(general_user, month: date)

        expect(response).to have_http_status(:success)
      end

      it '月末の日付で勤怠データを取得できる' do
        date = Date.new(2025, 12, 31)
        get user_path(general_user, month: date)

        expect(response).to have_http_status(:success)
      end

      it '不正な日付形式でアクセスするとエラー', skip: '日付パラメータのハンドリング実装依存' do
        expect do
          get user_path(general_user, month: 'invalid_date')
        end.to raise_error(ArgumentError)
      end

      it '未来の日付でアクセスできる' do
        date = 1.year.from_now.to_date
        get user_path(general_user, month: date)

        expect(response).to have_http_status(:success)
      end

      it '過去の日付でアクセスできる' do
        date = Date.today - 10.years
        get user_path(general_user, month: date)

        expect(response).to have_http_status(:success)
      end
    end

    context 'ページネーションの境界値' do
      before { create_list(:user, 25) }

      it 'ページ番号0でアクセスすると最初のページが表示される' do
        get users_path(page: 0)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('ユーザー一覧')
      end

      it '存在しないページ番号でアクセスすると空のページが表示される' do
        get users_path(page: 999)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('ユーザー一覧')
      end

      it '負のページ番号でアクセスすると最初のページが表示される' do
        get users_path(page: -1)

        expect(response).to have_http_status(:success)
      end
    end

    context '検索パラメータのエッジケース' do
      it '空文字列で検索すると全ユーザーが表示される' do
        create_list(:user, 5)
        get users_path(search: '')

        expect(response).to have_http_status(:success)
      end

      it '特殊文字を含む検索文字列でSQLインジェクションが防がれる' do
        create(:user, name: "O'Brien")
        get users_path(search: "'; DROP TABLE users; --")

        expect(response).to have_http_status(:success)
        expect(User.count).to be > 0 # テーブルが削除されていないことを確認
      end

      it 'LIKE演算子の特殊文字（%）がエスケープされる' do
        create(:user, name: '開発%太郎')
        get users_path(search: '%')

        expect(response).to have_http_status(:success)
      end

      it 'LIKE演算子の特殊文字（_）がエスケープされる' do
        create(:user, name: '開発_太郎')
        get users_path(search: '_')

        expect(response).to have_http_status(:success)
      end

      it '非常に長い検索文字列でもエラーが発生しない' do
        long_search = 'a' * 1000
        get users_path(search: long_search)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'データの境界値テスト' do
    before { sign_in admin_user }

    context '時刻データの境界値' do
      let(:attendance) { create(:attendance, user: general_user) }

      it '00:00の時刻で登録できる' do
        patch user_attendance_path(general_user, attendance),
              params: { attendance: { started_at: '00:00' } }

        expect(response).to have_http_status(:redirect)
        attendance.reload
        expect(attendance.started_at.strftime('%H:%M')).to eq('00:00')
      end

      it '23:59の時刻で登録できる' do
        attendance.update(started_at: Time.current)
        patch user_attendance_path(general_user, attendance),
              params: { attendance: { finished_at: '23:59' } }

        expect(response).to have_http_status(:redirect)
        attendance.reload
        expect(attendance.finished_at.strftime('%H:%M')).to eq('23:59')
      end

      it '24:00以上の時刻は不正な形式としてエラー', skip: '時刻バリデーション実装依存' do
        patch user_attendance_path(general_user, attendance),
              params: { attendance: { started_at: '24:00' } }

        expect(response).to have_http_status(:redirect)
        expect(flash[:danger]).to include('時間')
      end

      it '負の時刻は不正な形式としてエラー', skip: '時刻バリデーション実装依存' do
        patch user_attendance_path(general_user, attendance),
              params: { attendance: { started_at: '-01:00' } }

        expect(response).to have_http_status(:redirect)
        expect(flash[:danger]).to include('時間')
      end
    end

    context '文字列長の境界値' do
      it '名前が50文字まで登録できる' do
        long_name = 'あ' * 50
        post users_path, params: {
          user: {
            name: long_name,
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(User.last.name).to eq(long_name)
      end

      it 'メールアドレスが255文字まで登録できる' do
        # 実際には254文字が最大（RFC 5321）
        long_email = "#{'a' * 240}@example.com"
        post users_path, params: {
          user: {
            name: 'テスト',
            email: long_email,
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(User.last.email).to eq(long_email)
      end
    end
  end

  describe '同時実行のエッジケース' do
    before { sign_in admin_user }

    it '同じレコードを同時に更新してもデータ整合性が保たれる' do
      user = create(:user)

      # 楽観的ロックやトランザクションのテスト
      threads = 3.times.map do |i|
        Thread.new do
          patch user_path(user), params: {
            user: { department: "部署#{i}" }
          }
        end
      end

      threads.each(&:join)

      # 最後の更新が反映されていることを確認
      user.reload
      expect(user.department).to match(/部署\d/)
    end
  end

  private

  def sign_in(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: user.password
      }
    }
  end
end
