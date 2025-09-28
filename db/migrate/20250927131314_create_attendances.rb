class CreateAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.string :note, limit: 50
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :attendances, [:user_id, :worked_on], unique: true
  end
end
