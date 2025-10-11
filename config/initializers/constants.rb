# frozen_string_literal: true

# アプリケーション全体で使用する定数
module AppConstants
  # ページネーション関連
  module Pagination
    DEFAULT_PER_PAGE = 20 # デフォルトのページあたり表示件数
  end

  # タイムアウト関連
  module Timeout
    FETCH_TIMEOUT = 30_000 # fetchのタイムアウト時間（ミリ秒）
  end

  # フラッシュメッセージ関連
  module FlashMessages
    # 認証・認可関連
    LOGIN_REQUIRED = 'ログインしてください。'
    ACCESS_DENIED = 'アクセス権限がありません。'
    ADMIN_REQUIRED = '管理者権限が必要です。'

    # 承認関連
    APPROVAL_COMPLETED = '承認処理が完了しました'
  end
end
