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
    approver_id = params[:approver_id]

    raise "承認者を選択してください" if approver_id.blank?

    change_count = 0

    ActiveRecord::Base.transaction do
      update_attendances_params.each do |id, attendance_params|
        attendance = @user.attendances.find(id)

        # 変更があるかチェック
        if attendance_changes?(attendance, attendance_params)
          create_attendance_change_request(attendance, attendance_params, approver_id)
          change_count += 1
        end
      end
    end

    raise "変更がありません。勤怠時間を変更してから申請してください。" if change_count.zero?

    change_count
  end

  def attendance_changes?(attendance, attendance_params)
    return false if attendance_params[:started_at].blank? && attendance_params[:finished_at].blank?

    started_changed?(attendance, attendance_params) || finished_changed?(attendance, attendance_params)
  end

  def started_changed?(attendance, attendance_params)
    return false unless attendance_params[:started_at].present?

    new_started = parse_time_for_date(attendance_params[:started_at], attendance.worked_on)
    new_started != attendance.started_at
  end

  def finished_changed?(attendance, attendance_params)
    return false unless attendance_params[:finished_at].present?

    new_finished = parse_time_for_date(attendance_params[:finished_at], attendance.worked_on)
    new_finished != attendance.finished_at
  end

  def create_attendance_change_request(attendance, attendance_params, approver_id)
    requested_times = parse_requested_times(attendance, attendance_params)
    validate_change_request(attendance, attendance_params, requested_times)

    AttendanceChangeRequest.create!(
      attendance:,
      requester: @user,
      approver_id:,
      original_started_at: attendance.started_at,
      original_finished_at: attendance.finished_at,
      requested_started_at: requested_times[:started] || attendance.started_at,
      requested_finished_at: requested_times[:finished] || attendance.finished_at,
      change_reason: attendance_params[:note],
      status: :pending
    )
  end

  def parse_requested_times(attendance, attendance_params)
    {
      started: if attendance_params[:started_at].present?
                 parse_time_for_date(attendance_params[:started_at],
                                     attendance.worked_on)
               end,
      finished: if attendance_params[:finished_at].present?
                  parse_time_for_date(attendance_params[:finished_at],
                                      attendance.worked_on)
                end
    }
  end

  def validate_change_request(attendance, attendance_params, requested_times)
    # 備考（変更理由）のバリデーション
    raise "#{attendance.worked_on.strftime('%m/%d')}の変更理由（備考）を入力してください" if attendance_params[:note].blank?

    # 時刻のバリデーション
    validate_requested_times(attendance, requested_times)
  end

  def validate_requested_times(attendance, requested_times)
    return unless requested_times[:started].present? && requested_times[:finished].present?
    return if requested_times[:started] < requested_times[:finished]

    raise "#{attendance.worked_on.strftime('%m/%d')}の出勤時間が退勤時間より遅いか同じ時間です"
  end

  def handle_update_success
    change_count = @change_count || 0
    flash[:success] = "#{change_count}件の勤怠変更申請を送信しました"
    redirect_to user_path(@user)
  end

  def validate_attendance_times(attendance)
    return unless attendance.started_at.present? && attendance.finished_at.present?

    return if attendance.started_at < attendance.finished_at

    raise "#{attendance.worked_on.strftime('%m/%d')}の出勤時間が退勤時間より遅いか同じ時間です"
  end

  def handle_update_error(error)
    Rails.logger.error "Attendance update error: #{error.message}"

    flash.now[:danger] = format_error_message(error)
    prepare_error_view

    render 'edit_one_month', status: :unprocessable_entity
  end

  def format_error_message(error)
    case error.message
    when /承認者を選択してください/
      "承認者を選択してください。"
    when /変更がありません/
      "変更がありません。勤怠時間を変更してから申請してください。"
    when /変更理由（備考）を入力してください/, /出勤時間が退勤時間より/
      error.message
    else
      "勤怠変更申請の送信に失敗しました。#{error.message}"
    end
  end

  def prepare_error_view
    @attendances = fetch_monthly_attendances
    @worked_sum = @attendances.where.not(started_at: nil, finished_at: nil).count
    @form_params = params[:attendances] || {}
    @approver_id = params[:approver_id]
  end
end
