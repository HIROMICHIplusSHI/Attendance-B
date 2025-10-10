# frozen_string_literal: true

class ErrorReportsController < ApplicationController
  # CSRF保護をスキップ（JavaScriptからのPOSTを受け付けるため）
  skip_before_action :verify_authenticity_token, only: [:create]

  # JavaScriptエラーをログに記録
  def create
    error_data = error_report_params

    log_javascript_error(error_data)

    head :ok
  rescue StandardError => e
    Rails.logger.error("[ERROR] JavaScriptエラーレポートの処理に失敗: #{e.message}")
    head :internal_server_error
  end

  private

  def error_report_params
    params.permit(:message, :url, :line, :column, :error_type, :user_agent, :context)
  end

  def log_javascript_error(error_data)
    log_data = {
      type: 'JavaScript Error',
      message: error_data[:message],
      url: error_data[:url],
      line: error_data[:line],
      column: error_data[:column],
      error_type: error_data[:error_type],
      user_agent: error_data[:user_agent] || request.user_agent,
      context: error_data[:context],
      user: current_user_info_for_js_error,
      timestamp: Time.current.iso8601,
      ip: request.remote_ip
    }

    Rails.logger.error('[JavaScript Error]')
    Rails.logger.error("  詳細: #{log_data.to_json}")
  end

  def current_user_info_for_js_error
    return { id: nil, name: 'ゲスト' } unless current_user

    {
      id: current_user.id,
      name: current_user.name,
      role: current_user.role
    }
  end
end
