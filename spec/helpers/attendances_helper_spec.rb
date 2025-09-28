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

  describe "#round_to_15_minutes" do
    it "15分単位に切り下げること" do
      time = Time.zone.parse("9:07")
      expect(helper.round_to_15_minutes(time)).to eq(Time.zone.parse("9:00"))
    end

    it "15分単位の時刻はそのまま返すこと" do
      time = Time.zone.parse("9:15")
      expect(helper.round_to_15_minutes(time)).to eq(Time.zone.parse("9:15"))
    end

    it "29分は15分に切り下げること" do
      time = Time.zone.parse("9:29")
      expect(helper.round_to_15_minutes(time)).to eq(Time.zone.parse("9:15"))
    end

    it "nil値の場合はnilを返すこと" do
      expect(helper.round_to_15_minutes(nil)).to be_nil
    end
  end

  describe "#format_time_15min" do
    it "15分単位に切り下げた時刻をフォーマットして返すこと" do
      time = Time.zone.parse("9:07")
      expect(helper.format_time_15min(time)).to eq("09:00")
    end

    it "nil値の場合はnilを返すこと" do
      expect(helper.format_time_15min(nil)).to be_nil
    end
  end

  describe "#working_times" do
    it "15分単位に丸めた勤務時間を10進数で正しく計算すること" do
      start_time = Time.zone.parse("9:07")   # 9:00に丸められる
      finish_time = Time.zone.parse("17:37") # 17:30に丸められる

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("8.50")
    end

    it "1時間未満の勤務時間を正しく計算すること" do
      start_time = Time.zone.parse("9:07")   # 9:00に丸められる
      finish_time = Time.zone.parse("9:37")  # 9:30に丸められる

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("0.50")
    end

    it "15分単位で正確に計算すること" do
      start_time = Time.zone.parse("9:02")   # 9:00に丸められる
      finish_time = Time.zone.parse("17:17") # 17:15に丸められる

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("8.25")
    end

    it "境界値のテスト（切り下げ確認）" do
      start_time = Time.zone.parse("9:14")   # 9:00に丸められる
      finish_time = Time.zone.parse("17:44") # 17:30に丸められる

      result = helper.working_times(start_time, finish_time)
      expect(result).to eq("8.50")
    end

    it "nil値の場合は「未計算」を返すこと" do
      expect(helper.working_times(nil, nil)).to eq("未計算")
      expect(helper.working_times(Time.zone.parse("9:00"), nil)).to eq("未計算")
      expect(helper.working_times(nil, Time.zone.parse("17:00"))).to eq("未計算")
    end
  end
end
