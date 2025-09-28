require 'rails_helper'

RSpec.describe AttendancesHelper, type: :helper do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }
  let(:today) { Date.current }
  let(:yesterday) { Date.yesterday }

  describe "#attendance_state" do
    context "当日の勤怠データの場合" do
      let(:attendance) { user.attendances.create!(worked_on: today) }

      it "出勤時間が未記録の場合は「出勤」を返すこと" do
        expect(helper.attendance_state(attendance)).to eq('出勤')
      end

      it "出勤済みで退勤時間が未記録の場合は「退勤」を返すこと" do
        attendance.update!(started_at: Time.zone.parse("9:00"))
        expect(helper.attendance_state(attendance)).to eq('退勤')
      end

      it "出勤・退勤ともに記録済みの場合はfalseを返すこと" do
        attendance.update!(
          started_at: Time.zone.parse("9:00"),
          finished_at: Time.zone.parse("18:00")
        )
        expect(helper.attendance_state(attendance)).to eq(false)
      end
    end

    context "当日以外の勤怠データの場合" do
      let(:attendance) { user.attendances.create!(worked_on: yesterday) }

      it "出勤時間が未記録でもfalseを返すこと" do
        expect(helper.attendance_state(attendance)).to eq(false)
      end

      it "出勤済みで退勤時間が未記録でもfalseを返すこと" do
        attendance.update!(started_at: Time.zone.parse("9:00"))
        expect(helper.attendance_state(attendance)).to eq(false)
      end
    end
  end

  describe "#working_times" do
    it "勤務時間を10進数で正しく計算すること" do
      start_time = Time.zone.parse("9:00")
      finish_time = Time.zone.parse("17:30")

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("8.50")
    end

    it "1時間未満の勤務時間を正しく計算すること" do
      start_time = Time.zone.parse("9:00")
      finish_time = Time.zone.parse("9:30")

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("0.50")
    end

    it "分単位で正確に計算すること" do
      start_time = Time.zone.parse("9:00")
      finish_time = Time.zone.parse("17:15")

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("8.25")
    end
  end
end
