class ChangeOriginalTimesToNullableInAttendanceChangeRequests < ActiveRecord::Migration[7.1]
  def change
    change_column_null :attendance_change_requests, :original_started_at, true
    change_column_null :attendance_change_requests, :original_finished_at, true
  end
end
