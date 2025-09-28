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
    create_missing_attendance_records(attendances)
    fetch_monthly_attendances
  end

  def fetch_monthly_attendances
    @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  end

  def create_missing_attendance_records(attendances)
    one_month = [*@first_day..@last_day]
    return if one_month.count == attendances.count

    missing_days = one_month - attendances.pluck(:worked_on)
    missing_days.each { |day| @user.attendances.create!(worked_on: day) }
  end

  def calculate_worked_sum
    fetch_monthly_attendances.where.not(started_at: nil, finished_at: nil).count
  end
end
