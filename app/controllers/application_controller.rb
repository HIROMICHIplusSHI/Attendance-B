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
    flash[:danger] = "ログインしてください。"
    redirect_to login_path
  end

  # 管理者かどうか確認
  def admin_user
    return if current_user&.admin?

    flash[:danger] = "管理者権限が必要です。"
    redirect_to(root_path)
  end

  # 正しいユーザーかどうか確認
  def correct_user
    @user = User.find(params[:id])
    return if current_user?(@user)

    flash[:danger] = "アクセス権限がありません。"
    redirect_to(root_path)
  end

  # 管理者または正しいユーザーかどうか確認
  def admin_or_correct_user
    return true if current_user&.admin?
    return false unless current_user

    @user = User.find(params[:id]) if params[:id]
    return true if current_user?(@user)

    # マネージャーが部下のページを閲覧できるようにする
    return true if current_user.manager? && @user.manager_id == current_user.id

    false
  end

  # 月次データ設定
  def set_one_month
    set_month_range
    set_attendances
    ensure_attendance_records_exist
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

    missing_days = one_month - @attendances.pluck(:worked_on)
    missing_days.each { |day| @user.attendances.create!(worked_on: day) }
    set_attendances
  end

  def calculate_work_statistics
    @worked_sum = @attendances.where.not(started_at: nil).count
    @total_working_times = 0.0
  end
end
