module AttendanceManagement
  extend ActiveSupport::Concern

  private

  # 1ヶ月勤怠一括編集用のヘルパーメソッド
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

  def update_attendances_params
    params.require(:attendances).permit!
  end

  def parse_time_for_date(time_string, date)
    return nil if time_string.blank?

    begin
      Time.zone.parse("#{date} #{time_string}")
    rescue ArgumentError
      raise "無効な時間形式です: #{time_string}"
    end
  end

  def admin_or_correct_user(user)
    current_user.admin? || current_user == user
  end

  def prepare_edit_view
    set_month_range
    @attendances = fetch_monthly_attendances
    @worked_sum = @attendances.where.not(started_at: nil, finished_at: nil).count
  end

  def update_attendance_time(attendance, attendance_params)
    update_time_field(attendance, :started_at, attendance_params[:started_at])
    update_time_field(attendance, :finished_at, attendance_params[:finished_at])
    update_note_field(attendance, attendance_params)
    validate_attendance_times(attendance)
    save_attendance(attendance)
  end

  def update_time_field(attendance, field, time_value)
    return unless time_value

    if time_value.present?
      parsed_time = parse_time_for_date(time_value, attendance.worked_on)
      attendance.send("#{field}=", parsed_time) if parsed_time
    elsif time_value.empty?
      attendance.send("#{field}=", nil)
    end
  end

  def update_note_field(attendance, attendance_params)
    attendance.note = attendance_params[:note] if attendance_params.key?(:note)
  end

  def save_attendance(attendance)
    return if attendance.save

    raise "勤怠データの保存に失敗しました: #{attendance.errors.full_messages.join(', ')}"
  end

  def check_access_permission
    return if admin_or_correct_user(@user)

    flash[:danger] = ::AppConstants::FlashMessages::ACCESS_DENIED
    redirect_to root_path
  end

  def process_bulk_attendance_update
    ActiveRecord::Base.transaction do
      update_attendances_params.each do |id, attendance_params|
        attendance = @user.attendances.find(id)
        update_attendance_time(attendance, attendance_params)
      end
    end
  end

  def handle_update_success
    flash[:success] = '1ヶ月の勤怠情報を更新しました'
    redirect_to user_path(@user)
  end

  def validate_attendance_times(attendance)
    return unless attendance.started_at.present? && attendance.finished_at.present?

    return if attendance.started_at < attendance.finished_at

    raise "#{attendance.worked_on.strftime('%m/%d')}の出勤時間が退勤時間より遅いか同じ時間です"
  end

  def handle_update_error(error)
    Rails.logger.error "Attendance update error: #{error.message}"
    flash[:danger] = error.message.include?('出勤時間が退勤時間より') ? error.message : '勤怠情報の更新に失敗しました'
    redirect_to edit_one_month_user_attendances_path(@user, date: @first_day)
  end
end
