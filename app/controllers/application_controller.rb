class ApplicationController < ActionController::Base
  include SessionsHelper

  # テスト環境ではCSRF保護を無効化
  protect_from_forgery with: :exception, unless: -> { Rails.env.test? }

  # 曜日配列（定数）
  DAYS_OF_THE_WEEK = %w[日 月 火 水 木 金 土].freeze

  private

  # ログイン済みユーザーかどうか確認
  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = ::AppConstants::FlashMessages::LOGIN_REQUIRED
    redirect_to login_path
  end

  # 管理者かどうか確認
  def admin_user
    return if current_user&.admin?

    flash[:danger] = ::AppConstants::FlashMessages::ADMIN_REQUIRED
    redirect_to(root_path)
  end

  # 正しいユーザーかどうか確認
  def correct_user
    @user = User.find(params[:id])
    return if current_user?(@user)

    flash[:danger] = ::AppConstants::FlashMessages::ACCESS_DENIED
    redirect_to(root_path)
  end

  # 管理者または正しいユーザーかどうか確認
  def admin_or_correct_user
    return true if current_user&.admin?
    return false unless current_user

    @user = User.find(params[:id]) if params[:id]
    current_user?(@user) || manager_of_user?
  end

  def manager_of_user?
    return false unless current_user.manager? && @user

    # 自分が承認者として指定されている申請があるユーザーのみ閲覧可能
    MonthlyApproval.exists?(user: @user, approver: current_user) ||
      OvertimeRequest.exists?(user: @user, approver: current_user) ||
      AttendanceChangeRequest.exists?(requester: @user, approver: current_user)
  end

  # 月次データ設定
  def set_one_month
    set_month_range
    set_attendances
    # ロックタイムアウト回避のため、レコード自動作成をコメントアウト
    # ensure_attendance_records_exist
    calculate_work_statistics
  end

  def set_month_range
    @first_day = params[:date]&.to_date || Date.current.beginning_of_month
    @last_day = @first_day.end_of_month
  end

  def set_attendances
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  end

  def ensure_attendance_records_exist
    one_month = [*@first_day..@last_day]
    return if one_month.count == @attendances.count

    existing_dates = @attendances.pluck(:worked_on)
    missing_days = one_month - existing_dates
    return if missing_days.empty?

    # レコードを1件ずつ作成（find_or_create_byで重複を回避）
    missing_days.each do |day|
      @user.attendances.find_or_create_by(worked_on: day)
    rescue ActiveRecord::RecordNotUnique
      # 並行リクエストで既に作成された場合はスキップ
      next
    end
    set_attendances
  end

  def calculate_work_statistics
    @worked_sum = @attendances.where.not(started_at: nil).count
    @total_working_times = 0.0
  end

  # 共通エラーレスポンス（JSON）
  # @param errors [Array, Hash, ActiveModel::Errors] エラー情報
  # @param status [Symbol] HTTPステータスコード
  def render_error_json(errors, status: :unprocessable_entity)
    formatted_errors = format_errors_for_json(errors)
    render json: { status: 'error', errors: formatted_errors }, status:
  end

  # エラー情報を統一形式に整形
  # @return [Hash] { field_name: ['message1', 'message2'], base: ['general error'] }
  def format_errors_for_json(errors)
    case errors
    when Array
      # 文字列配列の場合は base キーに格納
      { base: errors }
    when ActiveModel::Errors
      # ActiveModel::Errors の場合は Hash に変換
      errors.to_hash
    when Hash
      # 既にHash形式の場合はそのまま
      errors
    else
      # その他の場合は base に文字列として格納
      { base: [errors.to_s] }
    end
  end

  # エラー発生時に詳細情報をログに記録
  # @param message [String] エラーメッセージ
  # @param context [Hash] コンテキスト情報
  def log_error_with_context(message, context = {})
    log_data = {
      message:,
      timestamp: Time.current.iso8601,
      user: current_user_info,
      request: request_info
    }.merge(context)

    Rails.logger.error("[ERROR] #{message}")
    Rails.logger.error("  詳細: #{log_data.to_json}")
  end

  # 現在のユーザー情報を取得
  def current_user_info
    return { id: nil, name: 'ゲスト', role: 'guest' } unless current_user

    {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email,
      role: current_user.role
    }
  end

  # リクエスト情報を取得
  def request_info
    {
      method: request.method,
      path: request.path,
      params: request.params.except('controller', 'action', 'password', 'password_confirmation').to_json,
      ip: request.remote_ip,
      user_agent: request.user_agent
    }
  end
end
