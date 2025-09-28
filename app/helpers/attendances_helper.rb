module AttendancesHelper
  # 出勤/退勤ボタンの表示制御
  def attendance_state(attendance)
    if Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    false # 当日以外またはすでに退勤済み → ボタン非表示
  end

  # 時刻を15分単位に丸める（切り下げ）
  def round_to_15_minutes(time)
    return nil if time.nil?

    minutes = time.min
    rounded_minutes = (minutes / 15) * 15
    time.change(min: rounded_minutes, sec: 0)
  end

  # 15分単位表示用の勤務時間計算（10進数表示：8.50時間など）
  def working_times(start, finish)
    return "未計算" if start.nil? || finish.nil?

    # 15分単位に丸めた時刻で計算
    rounded_start = round_to_15_minutes(start)
    rounded_finish = round_to_15_minutes(finish)

    format("%.2f", (((rounded_finish - rounded_start) / 60) / 60.0))
  end

  # 15分単位表示用の時刻フォーマット
  def format_time_15min(time)
    return nil if time.nil?

    round_to_15_minutes(time).strftime("%H:%M")
  end
end
