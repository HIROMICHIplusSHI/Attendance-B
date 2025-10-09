class AttendanceLogService
  def initialize(user, first_day, last_day)
    @user = user
    @first_day = first_day
    @last_day = last_day
  end

  def fetch_logs
    approved_requests = fetch_approved_change_requests
    grouped_requests = approved_requests.group_by(&:attendance_id)
    logs = build_attendance_logs(grouped_requests)
    logs.sort_by { |log| log[:worked_on] }
  end

  private

  def fetch_approved_change_requests
    @user.attendance_change_requests
         .includes(:attendance)
         .where(status: :approved)
         .where(attendances: { worked_on: @first_day..@last_day })
         .references(:attendances)
         .order(:created_at)
  end

  def build_attendance_logs(grouped_requests)
    grouped_requests.map do |_attendance_id, requests|
      {
        worked_on: requests.first.attendance.worked_on,
        changes: requests.map do |req|
          {
            before_started_at: req.original_started_at,
            before_finished_at: req.original_finished_at,
            after_started_at: req.requested_started_at,
            after_finished_at: req.requested_finished_at
          }
        end
      }
    end
  end
end
