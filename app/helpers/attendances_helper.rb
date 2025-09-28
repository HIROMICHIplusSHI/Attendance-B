module AttendancesHelper
  # 出勤/退勤ボタンの表示制御
  def attendance_state(attendance)
    if Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    false # 当日以外またはすでに退勤済み → ボタン非表示
  end

  # 勤務時間計算（10進数表示：8.50時間など）
  def working_times(start, finish)
    return "未計算" if start.nil? || finish.nil?

    format("%.2f", (((finish - start) / 60) / 60.0))
  end
end
