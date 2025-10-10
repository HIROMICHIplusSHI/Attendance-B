# frozen_string_literal: true

# JSON レスポンスの共通処理を提供する Concern
module JsonResponder
  extend ActiveSupport::Concern

  # 成功時のJSONレスポンス
  # @param message [String] 成功メッセージ
  # @param redirect_url [String] リダイレクト先URL
  # @param data [Hash] 追加データ（オプション）
  def render_success_json(message, redirect_url, data = {})
    render json: {
      status: 'success',
      message:,
      redirect_url:
    }.merge(data)
  end

  # 成功/失敗に応じたレスポンス
  # @param success [Boolean] 成功フラグ
  # @param options [Hash] オプション
  # @option options [String] :success_message 成功時のメッセージ
  # @option options [String] :redirect_url 成功時のリダイレクト先
  # @option options [ActiveModel::Errors, Array, Hash] :errors エラー情報
  # @option options [String] :html_view HTML表示用のビュー名
  # @option options [String, Boolean] :layout レイアウト指定
  def respond_with_json(success, **options)
    respond_to do |format|
      if success
        flash[:success] = options[:success_message]
        format.html { redirect_to options[:redirect_url] }
        format.json { render_success_json(options[:success_message], options[:redirect_url]) }
      else
        format.html { render options[:html_view], layout: options[:layout] }
        format.json { render_error_json(options[:errors]) }
      end
    end
  end
end
