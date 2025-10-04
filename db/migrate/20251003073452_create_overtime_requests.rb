class CreateOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :overtime_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.date :worked_on, null: false
      t.datetime :estimated_end_time, null: false
      t.text :business_content, null: false
      t.boolean :next_day_flag, default: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
