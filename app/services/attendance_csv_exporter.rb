class AttendanceCsvExporter
  def initialize(user, first_day, last_day)
    @user = user
    @first_day = first_day
    @last_day = last_day
  end

  def export
    attendances = fetch_exportable_attendances
    generate_csv(attendances)
  end

  def filename
    "#{@user.name}_#{@first_day.strftime('%Y%m')}_勤怠.csv"
  end

  private

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

  def generate_csv(attendances)
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
