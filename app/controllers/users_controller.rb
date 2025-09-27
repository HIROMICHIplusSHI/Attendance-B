class UsersController < ApplicationController
  before_action :logged_in_user, only: [:show]
  before_action :set_user, only: [:show]
  before_action :set_one_month, only: [:show]

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

  def show; end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_one_month
    set_month_range
    @attendances = fetch_monthly_attendances
    create_missing_attendance_records
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = 'ログインしてください'
    redirect_to login_path
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
