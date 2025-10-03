require 'rails_helper'

RSpec.describe MonthlyApproval, type: :model do
  describe 'アソシエーション' do
    it 'userに属していること' do
      expect(MonthlyApproval.reflect_on_association(:user).macro).to eq :belongs_to
    end

    it 'approverに属していること' do
      expect(MonthlyApproval.reflect_on_association(:approver).macro).to eq :belongs_to
      expect(MonthlyApproval.reflect_on_association(:approver).options[:class_name]).to eq 'User'
    end
  end

  describe 'バリデーション' do
    let(:user) { User.create(name: "一般", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:approval) do
      MonthlyApproval.new(
        user: user,
        approver: approver,
        target_month: Date.today.beginning_of_month
      )
    end

    it '有効な月次承認が作成できること' do
      expect(approval).to be_valid
    end

    it 'userが必須であること' do
      approval.user = nil
      expect(approval).not_to be_valid
    end

    it 'approverが必須であること' do
      approval.approver = nil
      expect(approval).not_to be_valid
    end

    it 'target_monthが必須であること' do
      approval.target_month = nil
      expect(approval).not_to be_valid
    end

    it '同じユーザー・月の組み合わせは一意であること' do
      MonthlyApproval.create!(
        user: user,
        approver: approver,
        target_month: Date.today.beginning_of_month
      )

      duplicate = MonthlyApproval.new(
        user: user,
        approver: approver,
        target_month: Date.today.beginning_of_month
      )

      expect(duplicate).not_to be_valid
    end
  end

  describe 'ステータス管理' do
    let(:user) { User.create(name: "一般", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:approval) do
      MonthlyApproval.create(
        user: user,
        approver: approver,
        target_month: Date.today.beginning_of_month
      )
    end

    it 'デフォルトステータスはpendingであること' do
      expect(approval.status).to eq 'pending'
    end

    it 'ステータスをapprovedに変更できること' do
      approval.approved!
      expect(approval.status).to eq 'approved'
    end

    it 'ステータスをrejectedに変更できること' do
      approval.rejected!
      expect(approval.status).to eq 'rejected'
    end
  end

  describe '#approve!' do
    let(:user) { User.create(name: "一般", email: "user@example.com", password: "password") }
    let(:approver) { User.create(name: "承認者", email: "approver@example.com", password: "password") }
    let(:approval) do
      MonthlyApproval.create(
        user: user,
        approver: approver,
        target_month: Date.today.beginning_of_month
      )
    end

    it 'ステータスをapprovedに変更し、承認日時を記録すること' do
      approval.approve!
      expect(approval.status).to eq 'approved'
      expect(approval.approved_at).not_to be_nil
    end
  end
end
