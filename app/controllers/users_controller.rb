require 'csv'

class UsersController < ApplicationController
  include CsvImportable

  before_action :logged_in_user,
                only: %i[index show edit update destroy edit_basic_info update_basic_info import_csv export_csv]
  before_action :admin_user, only: %i[index destroy edit_basic_info update_basic_info import_csv]
  before_action :admin_or_correct_user_check, only: %i[edit update]
  before_action :set_user, only: %i[show edit update destroy edit_basic_info update_basic_info export_csv]
  before_action :set_one_month, only: %i[show export_csv]

  def index
    @users = User.all

    # 検索機能
    @users = @users.where("name LIKE ?", "%#{params[:search]}%") if params[:search].present?

    @users = @users.page(params[:page]).per(20).order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = 'アカウント作成が完了しました'
      redirect_to @user
    else
      flash.now[:danger] = 'エラーが発生しました'
      render 'new'
    end
  end

  def show
    # 管理者は自分の勤怠ページにアクセス不可
    if current_user.admin? && current_user?(@user)
      flash[:danger] = "管理者は勤怠機能を利用できません。"
      redirect_to users_path and return
    end

    # 既存のアクセス制御
    return if admin_or_correct_user

    flash[:danger] = "アクセス権限がありません。"
    redirect_to(root_path) and return
  end

  def edit; end

  def update
    if @user.update(user_params)
      flash[:success] = 'ユーザー情報を更新しました。'
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    @user.destroy
    flash[:success] = 'ユーザーを削除しました。'
    redirect_to users_path
  end

  def edit_basic_info
    respond_to do |format|
      format.html { render layout: false if request.xhr? }
    end
  end

  def update_basic_info
    respond_to do |format|
      if @user.update(basic_info_params)
        handle_successful_update(format)
      else
        handle_failed_update(format)
      end
    end
  end

  def export_csv
    # 権限制御
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "アクセス権限がありません。"
      redirect_to root_url and return
    end

    attendances = fetch_exportable_attendances
    csv_data = generate_attendance_csv(attendances)
    filename = "#{@user.name}_#{@first_day.strftime('%Y%m')}_勤怠.csv"

    send_data csv_data, filename:, type: 'text/csv; charset=utf-8'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_one_month
    # monthパラメータがあれば優先、なければdateパラメータを使用
    date_param = params[:month] || params[:date]
    result = MonthlyAttendanceService.new(@user, date_param).call
    @first_day = result[:first_day]
    @last_day = result[:last_day]
    @attendances = result[:attendances]
    @worked_sum = result[:worked_sum]
    @total_working_times = result[:total_working_times]

    # 残業申請データを取得（worked_onでインデックス化）
    @overtime_requests = @user.overtime_requests.where(worked_on: @first_day..@last_day).index_by(&:worked_on)
  end

  def user_params
    params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
  end

  def basic_info_params
    params.require(:user).permit(:department, :basic_time, :work_time, :role, :employee_number)
  end

  def admin_or_correct_user_check
    return if current_user&.admin?

    @user = User.find(params[:id])
    return if current_user?(@user)

    flash[:danger] = "アクセス権限がありません。"
    redirect_to(root_path)
  end

  def handle_successful_update(format)
    flash[:success] = '基本情報を更新しました。'
    format.html { redirect_to @user }
    format.json { render json: successful_update_json }
  end

  def handle_failed_update(format)
    format.html { render 'edit_basic_info', layout: request.xhr? ? false : 'application' }
    format.json { render json: { status: 'error', errors: @user.errors } }
  end

  def successful_update_json
    {
      status: 'success',
      message: '基本情報を更新しました。',
      redirect_url: user_path(@user)
    }
  end

  def fetch_exportable_attendances
    # pending状態の変更申請を除外
    pending_change_ids = @user.attendance_change_requests
                              .joins(:attendance)
                              .where(status: :pending)
                              .where(attendances: { worked_on: @first_day..@last_day })
                              .pluck(:attendance_id)

    @user.attendances
         .where(worked_on: @first_day..@last_day)
         .where.not(id: pending_change_ids)
         .order(:worked_on)
  end

  def generate_attendance_csv(attendances)
    bom = "\uFEFF"
    CSV.generate(bom, headers: true) do |csv|
      csv << %w[日付 曜日 出社時刻 退社時刻 在社時間 備考]
      attendances.each { |attendance| csv << format_attendance_row(attendance) }
    end
  end

  def format_attendance_row(attendance)
    [
      attendance.worked_on.strftime('%Y/%m/%d'),
      %w[日 月 火 水 木 金 土][attendance.worked_on.wday],
      attendance.started_at&.strftime('%H:%M') || '',
      attendance.finished_at&.strftime('%H:%M') || '',
      calculate_working_time(attendance),
      attendance.note || ''
    ]
  end

  def calculate_working_time(attendance)
    return '' unless attendance.started_at && attendance.finished_at

    format('%.2f', ((attendance.finished_at - attendance.started_at) / 1.hour))
  end
end
