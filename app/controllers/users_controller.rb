require 'csv'

class UsersController < ApplicationController
  include CsvImportable

  before_action :logged_in_user,
                only: %i[index show edit update destroy edit_basic_info update_basic_info import_csv export_csv
                         attendance_log]
  before_action :admin_user, only: %i[index destroy edit_basic_info update_basic_info import_csv]
  before_action :admin_or_correct_user_check, only: %i[edit update]
  before_action :set_user, only: %i[show edit update destroy edit_basic_info update_basic_info export_csv
                                    attendance_log]
  before_action :set_one_month, only: %i[show export_csv attendance_log]

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
    if @user.update(basic_info_params)
      flash[:success] = '基本情報を更新しました。'
      respond_to do |format|
        format.html { redirect_to @user }
        format.json { render json: { status: 'success', message: flash[:success], redirect_url: user_path(@user) } }
      end
    else
      respond_to do |format|
        format.html { render 'edit_basic_info', layout: request.xhr? ? false : 'application' }
        format.json { render json: { status: 'error', errors: @user.errors } }
      end
    end
  end

  def export_csv
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "アクセス権限がありません。"
      redirect_to root_url and return
    end

    exporter = AttendanceCsvExporter.new(@user, @first_day, @last_day)
    send_data exporter.export, filename: exporter.filename, type: 'text/csv; charset=utf-8'
  end

  def attendance_log
    head :forbidden and return unless current_user?(@user) || current_user.admin?

    service = AttendanceLogService.new(@user, @first_day, @last_day)
    @attendance_logs = service.fetch_logs

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_one_month
    date_param = params[:month] || params[:date]
    result = MonthlyAttendanceService.new(@user, date_param).call
    @first_day = result[:first_day]
    @last_day = result[:last_day]
    @attendances = result[:attendances]
    @worked_sum = result[:worked_sum]
    @total_working_times = result[:total_working_times]
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
end
