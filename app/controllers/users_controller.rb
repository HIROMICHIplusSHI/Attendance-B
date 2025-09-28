class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[index show edit update destroy edit_basic_info update_basic_info]
  before_action :admin_user, only: %i[index destroy edit_basic_info update_basic_info]
  before_action :correct_user, only: %i[edit update]
  before_action :set_user, only: %i[show edit update destroy edit_basic_info update_basic_info]
  before_action :set_one_month, only: [:show]

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
    redirect_to(root_path) unless admin_or_correct_user
    flash[:danger] = "アクセス権限がありません。" unless admin_or_correct_user
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
      redirect_to @user
    else
      render 'edit_basic_info'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_one_month
    set_month_range
    @attendances = fetch_monthly_attendances
    create_missing_attendance_records
    @worked_sum = @attendances.where.not(started_at: nil, finished_at: nil).count
    @total_working_times = 0.0
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def basic_info_params
    params.require(:user).permit(:department, :basic_time, :work_time)
  end

  def set_month_range
    @first_day = params[:date]&.to_date || Date.current.beginning_of_month
    @last_day = @first_day.end_of_month
  end

  def fetch_monthly_attendances
    @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  end

  def create_missing_attendance_records
    one_month = [*@first_day..@last_day]
    return if one_month.count == @attendances.count

    missing_days = one_month - @attendances.pluck(:worked_on)
    missing_days.each { |day| @user.attendances.create!(worked_on: day) }
    @attendances = fetch_monthly_attendances
  end
end
