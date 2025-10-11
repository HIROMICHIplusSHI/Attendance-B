class CreateMonthlyApprovals < ActiveRecord::Migration[7.1]
  def change
    create_table :monthly_approvals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.date :target_month, null: false
      t.integer :status, default: 0, null: false
      t.datetime :approved_at

      t.timestamps
    end
    add_index :monthly_approvals, [:user_id, :target_month], unique: true
  end
end
