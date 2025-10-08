class AddRoleAndEmployeeNumberToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :employee_number, :string
    add_index :users, :role
    add_index :users, :employee_number, unique: true

    # 既存データの移行
    reversible do |dir|
      dir.up do
        # 既存のadmin=trueユーザーをadmin roleに
        User.where(admin: true).update_all(role: 2)

        # 部下を持つユーザーをmanager roleに
        User.find_each do |user|
          next if user.admin?
          user.update_column(:role, 1) if user.subordinates.exists?
        end
      end
    end
  end
end
