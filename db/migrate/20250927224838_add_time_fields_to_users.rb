class AddTimeFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :basic_time, :datetime, default: Time.zone.parse("08:00:00")
    add_column :users, :work_time, :datetime, default: Time.zone.parse("07:30:00")
  end
end
