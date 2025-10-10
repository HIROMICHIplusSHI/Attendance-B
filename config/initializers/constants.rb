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
end
