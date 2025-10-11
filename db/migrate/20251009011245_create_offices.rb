class CreateOffices < ActiveRecord::Migration[7.1]
  def change
    create_table :offices do |t|
      t.integer :office_number
      t.string :name
      t.string :attendance_type

      t.timestamps
    end

    add_index :offices, :office_number, unique: true
  end
end
