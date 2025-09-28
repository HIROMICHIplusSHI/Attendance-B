class AttendancesController < ApplicationController
  before_action :logged_in_user
  before_action :set_user
  before_action :set_attendance, only: [:update]

  def edit_one_month
    # 簡単な実装（feature/15で完全実装予定）
  end

  def update
    if params[:attendance][:started_at].present?
      update_started_at
    elsif params[:attendance][:finished_at].present?
      update_finished_at
    else
      flash[:danger] = '時間の入力が必要です'
      redirect_to @user
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_attendance
    @attendance = @user.attendances.find(params[:id])
  end

  def attendance_params
    params.require(:attendance).permit(:started_at, :finished_at, :note)
  end

  def update_started_at
    return redirect_with_error('既に出勤時間が登録されています') if @attendance.started_at.present?

    parsed_time = validate_and_parse_time(params[:attendance][:started_at])
    return if performed?

    save_started_at(parsed_time)
  end

  def update_finished_at
    return redirect_with_error('出勤時間を先に登録してください') if @attendance.started_at.nil?
    return redirect_with_error('既に退勤時間が登録されています') if @attendance.finished_at.present?

    parsed_time = validate_and_parse_time(params[:attendance][:finished_at])
    return if performed?

    save_finished_at(parsed_time)
  end

  def redirect_with_error(message)
    flash[:danger] = message
    redirect_to @user
  end

  def validate_and_parse_time(time_string)
    parsed_time = parse_time(time_string)
    redirect_with_error('時間の形式が正しくありません') if parsed_time.nil?
    parsed_time
  end

  def save_started_at(parsed_time)
    @attendance.started_at = parsed_time
    if @attendance.save
      flash[:success] = '出勤時間を登録しました'
    else
      flash[:danger] = '出勤時間の登録に失敗しました'
    end
    redirect_to @user
  end

  def save_finished_at(parsed_time)
    @attendance.finished_at = parsed_time
    if @attendance.save
      flash[:success] = '退勤時間を登録しました'
    else
      flash[:danger] = '退勤時間の登録に失敗しました'
    end
    redirect_to @user
  end

  def parse_time(time_string)
    return nil if time_string.blank?

    begin
      # "HH:MM" 形式を当日の時刻として解析
      Time.zone.parse("#{Date.current} #{time_string}")
    rescue ArgumentError
      nil
    end
  end

  def logged_in_user
    return if logged_in?

    flash[:danger] = 'ログインしてください'
    redirect_to login_path
  end
end
