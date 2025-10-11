# frozen_string_literal: true

module RequestHelpers
  # ログインヘルパー
  def sign_in(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: user.password
      }
    }
  end

  # ログアウトヘルパー
  def sign_out
    delete logout_path
  end

  # JSONリクエスト用ヘッダー
  def json_headers
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  end

  # JSONレスポンスのパース
  def json_response
    JSON.parse(response.body)
  end

  # エラーメッセージの確認
  def expect_error_message(message)
    follow_redirect! if response.redirect?
    expect(response.body).to include(message)
  end

  # 成功メッセージの確認
  def expect_success_message(message)
    follow_redirect! if response.redirect?
    expect(response.body).to include(message)
  end

  # フラッシュメッセージの確認
  def expect_flash(type, message)
    expect(flash[type]).to eq(message)
  end

  # ページネーション付きリクエスト
  def get_paginated(path, page: 1, per: 20, **params)
    get path, params: params.merge(page:, per:)
  end

  # ファイルアップロードヘルパー
  def upload_file(path, file_path, content_type = 'text/csv')
    file = fixture_file_upload(file_path, content_type)
    post path, params: { file: }
  end

  # 管理者権限の確認
  def expect_admin_required
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(response.body).to include('管理者権限が必要です')
  end

  # アクセス権限の確認
  def expect_access_denied
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(response.body).to include('アクセス権限がありません')
  end

  # ログイン要求の確認
  def expect_login_required
    expect(response).to have_http_status(:redirect)
    expect(response).to redirect_to(login_path)
    follow_redirect!
    expect(response.body).to include('ログインしてください')
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
