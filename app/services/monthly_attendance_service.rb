class MonthlyAttendanceService
  def initialize(user, date = nil)
    @user = user
    @first_day = date&.to_date || Date.current.beginning_of_month
    @last_day = @first_day.end_of_month
  end

  def call
    {
      first_day: @first_day,
      last_day: @last_day,
      attendances: fetch_attendances_with_missing_records,
      worked_sum: calculate_worked_sum,
      total_working_times: 0.0
    }
  end

  private

  def fetch_attendances_with_missing_records
    attendances = fetch_monthly_attendances

    # 不足レコードがあれば作成
    create_missing_attendance_records(attendances) if attendances.count < (@last_day - @first_day + 1).to_i

    fetch_monthly_attendances
  end

  def fetch_monthly_attendances
    @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  end

  def create_missing_attendance_records(attendances)
    one_month = [*@first_day..@last_day]
    return if one_month.count == attendances.count

    existing_dates = attendances.pluck(:worked_on)
    missing_days = one_month - existing_dates
    return if missing_days.empty?

    # レコードを1件ずつ作成（find_or_create_byで重複を回避）
    missing_days.each do |day|
      @user.attendances.find_or_create_by(worked_on: day)
    rescue ActiveRecord::RecordNotUnique
      # 並行リクエストで既に作成された場合はスキップ
      next
    end
  end

  def calculate_worked_sum
    fetch_monthly_attendances.where.not(started_at: nil, finished_at: nil).count
  end
end
