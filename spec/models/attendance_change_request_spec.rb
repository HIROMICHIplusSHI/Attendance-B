require 'rails_helper'

RSpec.describe AttendanceChangeRequest, type: :model do
  describe 'アソシエーション' do
    it 'attendanceに属していること' do
      expect(AttendanceChangeRequest.reflect_on_association(:attendance).macro).to eq :belongs_to
    end

    it 'requesterに属していること' do
      expect(AttendanceChangeRequest.reflect_on_association(:requester).macro).to eq :belongs_to
      expect(AttendanceChangeRequest.reflect_on_association(:requester).options[:class_name]).to eq 'User'
    end

    it 'approverに属していること' do
      expect(AttendanceChangeRequest.reflect_on_association(:approver).macro).to eq :belongs_to
      expect(AttendanceChangeRequest.reflect_on_association(:approver).options[:class_name]).to eq 'User'
    end
  end

  describe 'バリデーション' do
    let(:user) { User.create(name: "申請者", email: "requester@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:attendance) { user.attendances.create(worked_on: Date.today, started_at: Time.current) }
    let(:request) do
      AttendanceChangeRequest.new(
        attendance:,
        requester: user,
        approver:,
        original_started_at: Time.current,
        original_finished_at: Time.current + 8.hours,
        requested_started_at: Time.current + 1.hour,
        requested_finished_at: Time.current + 9.hours
      )
    end

    it '有効な勤怠変更申請が作成できること' do
      expect(request).to be_valid
    end

    it 'attendanceが必須であること' do
      request.attendance = nil
      expect(request).not_to be_valid
    end

    it 'requesterが必須であること' do
      request.requester = nil
      expect(request).not_to be_valid
    end

    it 'approverが必須であること' do
      request.approver = nil
      expect(request).not_to be_valid
    end

    it 'original_started_atが必須であること' do
      request.original_started_at = nil
      expect(request).not_to be_valid
    end

    it 'original_finished_atが必須であること' do
      request.original_finished_at = nil
      expect(request).not_to be_valid
    end

    it 'requested_started_atが必須であること' do
      request.requested_started_at = nil
      expect(request).not_to be_valid
    end

    it 'requested_finished_atが必須であること' do
      request.requested_finished_at = nil
      expect(request).not_to be_valid
    end
  end

  describe 'ステータス管理' do
    let(:user) { User.create(name: "申請者", email: "requester@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:attendance) { user.attendances.create(worked_on: Date.today, started_at: Time.current) }
    let(:request) do
      AttendanceChangeRequest.create(
        attendance:,
        requester: user,
        approver:,
        original_started_at: Time.current,
        original_finished_at: Time.current + 8.hours,
        requested_started_at: Time.current + 1.hour,
        requested_finished_at: Time.current + 9.hours
      )
    end

    it 'デフォルトステータスはpendingであること' do
      expect(request.status).to eq 'pending'
    end

    it 'ステータスをapprovedに変更できること' do
      request.approved!
      expect(request.status).to eq 'approved'
    end

    it 'ステータスをrejectedに変更できること' do
      request.rejected!
      expect(request.status).to eq 'rejected'
    end
  end
end
