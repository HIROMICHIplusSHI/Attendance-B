class AddScheduledTimesAndCardIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :scheduled_start_time, :time, comment: '指定勤務開始時間（会社規則表示用）'
    add_column :users, :scheduled_end_time, :time, comment: '指定勤務終了時間（会社規則表示用）'
    add_column :users, :card_id, :string, comment: 'ICカードID（未実装）'

    add_index :users, :card_id, unique: true
  end
end
