require 'rails_helper'

RSpec.describe OvertimeRequest, type: :model do
  describe 'アソシエーション' do
    it 'userに属していること' do
      expect(OvertimeRequest.reflect_on_association(:user).macro).to eq :belongs_to
    end

    it 'approverに属していること' do
      expect(OvertimeRequest.reflect_on_association(:approver).macro).to eq :belongs_to
      expect(OvertimeRequest.reflect_on_association(:approver).options[:class_name]).to eq 'User'
    end
  end

  describe 'バリデーション' do
    let(:user) { User.create(name: "申請者", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:request) do
      OvertimeRequest.new(
        user: user,
        approver: approver,
        worked_on: Date.today,
        estimated_end_time: Time.current + 2.hours,
        business_content: "システムメンテナンス作業"
      )
    end

    it '有効な残業申請が作成できること' do
      expect(request).to be_valid
    end

    it 'userが必須であること' do
      request.user = nil
      expect(request).not_to be_valid
    end

    it 'approverが必須であること' do
      request.approver = nil
      expect(request).not_to be_valid
    end

    it 'worked_onが必須であること' do
      request.worked_on = nil
      expect(request).not_to be_valid
    end

    it 'estimated_end_timeが必須であること' do
      request.estimated_end_time = nil
      expect(request).not_to be_valid
    end

    it 'business_contentが必須であること' do
      request.business_content = nil
      expect(request).not_to be_valid
    end
  end

  describe 'ステータス管理' do
    let(:user) { User.create(name: "申請者", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:request) do
      OvertimeRequest.create(
        user: user,
        approver: approver,
        worked_on: Date.today,
        estimated_end_time: Time.current + 2.hours,
        business_content: "システムメンテナンス作業"
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

  describe 'next_day_flag' do
    let(:user) { User.create(name: "申請者", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:request) do
      OvertimeRequest.create(
        user: user,
        approver: approver,
        worked_on: Date.today,
        estimated_end_time: Time.current + 2.hours,
        business_content: "システムメンテナンス作業"
      )
    end

    it 'デフォルトはfalseであること' do
      expect(request.next_day_flag).to be false
    end
  end
end
