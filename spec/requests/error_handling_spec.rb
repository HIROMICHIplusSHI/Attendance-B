# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'エラーハンドリング', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:general_user) { create(:user) }

  describe 'JSONレスポンスのエラーハンドリング' do
    before { sign_in admin_user }

    it 'バリデーションエラーが適切なJSON形式で返される' do
      patch update_basic_info_user_path(general_user),
            params: {
              user: { basic_time: -1 }
            },
            headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json['status']).to eq('error')
      expect(json['errors']).to be_present
    end

    it '複数のバリデーションエラーが全て返される', skip: 'JSON形式での作成API未実装' do
      post users_path,
           params: {
             user: {
               name: '',
               email: '',
               password: 'short',
               password_confirmation: 'short'
             }
           },
           headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json['errors']).to be_a(Hash)
      expect(json['errors'].keys).to include('name', 'email', 'password')
    end

    it 'ネストされたエラーが正しく返される', skip: '一括更新のエラーハンドリング実装依存' do
      # 勤怠データの一括更新でエラーが発生した場合
      attendance = create(:attendance, user: general_user, worked_on: Date.current)

      patch update_one_month_user_attendances_path(general_user),
            params: {
              attendances: {
                attendance.id => {
                  started_at: '10:00',
                  finished_at: '09:00' # 終了時刻が開始時刻より前
                }
              }
            },
            headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:redirect)
      expect(flash[:danger]).to be_present
    end
  end

  describe 'CSRFトークンエラー' do
    it 'CSRFトークンなしのPOSTリクエストは拒否される' do
      # テスト環境ではCSRF保護が無効化されているため、このテストはスキップ
      skip 'CSRF protection is disabled in test environment'

      post users_path, params: {
        user: {
          name: 'テスト',
          email: 'test@example.com'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe '認証エラー' do
    it 'ログインしていない状態でアクセスするとログインページにリダイレクト' do
      get users_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include('ログインしてください')
    end

    it 'セッション切れ後のリクエストはログインページにリダイレクト' do
      sign_in general_user

      # セッションを削除
      delete logout_path

      # 保護されたページにアクセス
      get edit_user_path(general_user)

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(login_path)
    end
  end

  describe '認可エラー' do
    before { sign_in general_user }

    it '管理者権限がないユーザーは管理者ページにアクセスできない' do
      get users_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('管理者権限が必要です')
    end

    it '他のユーザーの情報は編集できない' do
      other_user = create(:user)
      get edit_user_path(other_user)

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('アクセス権限がありません')
    end

    it '自分の情報は編集できる' do
      get edit_user_path(general_user)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'データ不整合エラー' do
    before { sign_in admin_user }

    it '削除されたレコードの参照で404エラーが返される' do
      user = create(:user)
      user_id = user.id
      user.destroy

      get user_path(user_id)
      expect(response).to have_http_status(:not_found)
    end

    it '関連レコードが削除されている場合に404エラーが返される' do
      user = create(:user)
      attendance = create(:attendance, user:)
      user_id = user.id
      attendance_id = attendance.id

      # ユーザーを削除（dependent: :destroy で勤怠も削除される）
      user.destroy

      get user_attendance_path(user_id, attendance_id)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'パラメータの型エラー' do
    before { sign_in admin_user }

    it '数値が期待されるパラメータに文字列を渡すとエラー', skip: 'バリデーション実装依存' do
      patch update_basic_info_user_path(general_user),
            params: {
              user: { basic_time: 'invalid' }
            }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it '日付が期待されるパラメータに不正な文字列を渡すとエラー', skip: '日付パラメータのハンドリング実装依存' do
      expect {
        get user_path(general_user, month: 'not-a-date')
      }.to raise_error(ArgumentError)
    end
  end

  describe 'データベースエラーのハンドリング' do
    before { sign_in admin_user }

    it 'ユニーク制約違反のエラーが適切に処理される' do
      existing_user = create(:user, email: 'duplicate@example.com')

      post users_path, params: {
        user: {
          name: 'テスト',
          email: 'duplicate@example.com', # 既存のメールアドレス
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect(response).to have_http_status(:success) # フォームを再表示
      expect(response.body.include?('Email') || response.body.include?('すでに存在')).to be true
    end

    it 'NOT NULL制約違反のエラーが適切に処理される' do
      post users_path, params: {
        user: {
          name: '', # 空文字列でバリデーションエラー
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }

      expect(response).to have_http_status(:success) # フォームを再表示
      expect(response.body.include?('Name') || response.body.include?('入力')).to be true
    end
  end

  describe 'ファイルアップロードエラー' do
    before { sign_in admin_user }

    it 'CSVファイルが選択されていない場合のエラー' do
      post import_csv_users_path, params: { file: nil }

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('CSVファイルを選択してください')
    end

    it '不正な形式のCSVファイルのエラー' do
      file = fixture_file_upload('invalid.csv', 'text/csv')

      post import_csv_users_path, params: { file: }

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('CSVファイルの形式が不正です')
    end
  end

  describe 'エラーログの記録' do
    before { sign_in admin_user }

    it 'エラー発生時に詳細なログが記録される' do
      # ログ出力を確認
      expect(Rails.logger).to receive(:error).at_least(:once)

      patch update_basic_info_user_path(general_user),
            params: {
              user: { basic_time: -1 }
            }
    end

    it 'ユーザー情報とリクエスト情報がログに含まれる' do
      # コンテキスト付きエラーログのテスト
      expect(Rails.logger).to receive(:error).with(/ERROR/)
      expect(Rails.logger).to receive(:error).with(/詳細:/)

      patch update_basic_info_user_path(general_user),
            params: {
              user: { basic_time: -1 }
            }
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
