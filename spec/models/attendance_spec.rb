require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:user) { User.create(name: "テスト太郎", email: "test@example.com", password: "password") }

  describe '基本的なバリデーション' do
    let(:attendance) { user.attendances.build(worked_on: Date.current) }

    it '有効な勤怠データが作成できること' do
      expect(attendance).to be_valid
    end

    it '勤務日が必須であること' do
      attendance.worked_on = nil
      expect(attendance).not_to be_valid
      expect(attendance.errors[:worked_on]).to include("を入力してください")
    end

    it '同一ユーザーの同一日付で重複が許可されないこと' do
      user.attendances.create!(worked_on: Date.current)
      duplicate_attendance = user.attendances.build(worked_on: Date.current)
      expect(duplicate_attendance).not_to be_valid
      expect(duplicate_attendance.errors[:worked_on]).to include("はすでに存在します")
    end

    it '備考が50文字以内であること' do
      attendance.note = 'a' * 51
      expect(attendance).not_to be_valid
      expect(attendance.errors[:note]).to include("は50文字以内で入力してください")
    end
  end

  describe 'カスタムバリデーション' do
    let(:attendance) { user.attendances.build(worked_on: Date.current) }

    it '退勤時間があるのに出勤時間がない場合は無効であること' do
      attendance.finished_at = Time.current
      attendance.started_at = nil
      expect(attendance).not_to be_valid
      expect(attendance.errors[:started_at]).to include("を入力してください")
    end

    it '退勤時間が出勤時間より前の場合は無効であること' do
      attendance.started_at = Time.current
      attendance.finished_at = Time.current - 1.hour
      expect(attendance).not_to be_valid
      expect(attendance.errors[:finished_at]).to include("は出勤時間より後にしてください")
    end

    it '出勤時間と退勤時間が同じ場合は無効であること' do
      same_time = Time.current
      attendance.started_at = same_time
      attendance.finished_at = same_time
      expect(attendance).not_to be_valid
      expect(attendance.errors[:finished_at]).to include("は出勤時間より後にしてください")
    end
  end

  describe '関連付け' do
    it 'ユーザーに属していること' do
      expect(Attendance.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end
end
