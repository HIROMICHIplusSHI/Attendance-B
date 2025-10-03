class MonthlyApprovalsController < ApplicationController
  before_action :logged_in_user
  before_action :set_user

  def create
    # 既存の申請があれば上書き（再承認対応）
    @approval = @user.monthly_approvals.find_or_initialize_by(
      target_month: approval_params[:target_month]
    )

    @approval.approver_id = approval_params[:approver_id]
    @approval.status = :pending
    @approval.approved_at = nil

    set_flash_message
    redirect_to @user
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_flash_message
    if @approval.save
      flash[:success] = "#{format_target_month}の勤怠を申請しました。"
    else
      flash[:danger] = "申請に失敗しました: #{@approval.errors.full_messages.join(', ')}"
    end
  end

  def format_target_month
    month = @approval.target_month.is_a?(Date) ? @approval.target_month : Date.parse(@approval.target_month.to_s)
    l(month, format: :middle)
  end

  def approval_params
    params.require(:monthly_approval).permit(:approver_id, :target_month)
  end
end
