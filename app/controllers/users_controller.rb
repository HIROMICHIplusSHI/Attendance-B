class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[index show edit update destroy edit_basic_info update_basic_info]
  before_action :admin_user, only: %i[index destroy edit_basic_info update_basic_info]
  before_action :admin_or_correct_user_check, only: %i[edit update]
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
    respond_to do |format|
      if @user.update(basic_info_params)
        handle_successful_update(format)
      else
        handle_failed_update(format)
      end
    end
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
    params.require(:user).permit(:department, :basic_time, :work_time)
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
end
