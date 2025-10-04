class AddChangeReasonToAttendanceChangeRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :attendance_change_requests, :change_reason, :text
  end
end
