# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "MonthlyApprovals", type: :request do
  let(:user) { User.create!(name: "申請者", email: "user@example.com", password: "password") }
  let(:approver) { User.create!(name: "承認者", email: "approver@example.com", password: "password") }
  let(:target_month) { Date.current.beginning_of_month }

  before do
    post login_path, params: { session: { email: user.email, password: "password" } }
  end

  describe "POST /users/:user_id/monthly_approvals" do
    context "有効なパラメータの場合" do
      it "新しい月次承認申請が作成されること" do
        expect do
          post user_monthly_approvals_path(user), params: {
            monthly_approval: {
              approver_id: approver.id,
              target_month:
            }
          }
        end.to change(MonthlyApproval, :count).by(1)
      end

      it "ステータスがpendingに設定されること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.status).to eq 'pending'
      end

      it "成功メッセージが表示されること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(flash[:success]).to be_present
      end

      it "ユーザー詳細ページにリダイレクトされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(response).to redirect_to user_path(user)
      end
    end

    context "既存の申請がある場合（再承認）" do
      before do
        MonthlyApproval.create!(
          user:,
          approver:,
          target_month:,
          status: :approved,
          approved_at: Time.current
        )
      end

      it "既存レコードが上書きされること" do
        expect do
          post user_monthly_approvals_path(user), params: {
            monthly_approval: {
              approver_id: approver.id,
              target_month:
            }
          }
        end.not_to change(MonthlyApproval, :count)
      end

      it "ステータスがpendingにリセットされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.status).to eq 'pending'
      end

      it "approved_atがnilにリセットされること" do
        post user_monthly_approvals_path(user), params: {
          monthly_approval: {
            approver_id: approver.id,
            target_month:
          }
        }
        expect(MonthlyApproval.last.approved_at).to be_nil
      end
    end
  end
end
