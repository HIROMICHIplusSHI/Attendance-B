class CreateAttendanceChangeRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_change_requests do |t|
      t.references :attendance, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.datetime :original_started_at, null: false
      t.datetime :original_finished_at, null: false
      t.datetime :requested_started_at, null: false
      t.datetime :requested_finished_at, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
