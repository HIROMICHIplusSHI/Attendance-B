class MonthlyApprovalsController < ApplicationController
  before_action :logged_in_user
  before_action :set_user, only: [:create]
  before_action :require_manager, only: %i[index bulk_update]

  def index
    @approvals = MonthlyApproval.pending.where(approver: current_user)

    return unless request.xhr?

    render layout: false
  end

  def bulk_update
    selected_approvals = extract_selected_approvals

    return render_no_selection_error if selected_approvals.empty?
    return render_pending_status_error if pending_status?(selected_approvals)

    process_bulk_update(selected_approvals)
    handle_bulk_update_success
  rescue ActiveRecord::RecordInvalid => e
    handle_bulk_update_error(e)
  end

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

  def require_manager
    return if current_user.manager?

    redirect_to root_path, alert: '管理者権限が必要です'
  end

  def extract_selected_approvals
    approval_params = params[:approvals] || {}
    approval_params.select { |_id, attrs| attrs[:selected] == '1' }
  end

  def render_no_selection_error
    @approvals = MonthlyApproval.pending.where(approver: current_user)
    flash.now[:alert] = '承認する項目を選択してください'
    render :index, layout: false, status: :unprocessable_entity
  end

  def pending_status?(selected_approvals)
    selected_approvals.any? { |_id, attrs| attrs[:status] == 'pending' }
  rescue NoMethodError
    # ActionController::Parametersの場合
    selected_approvals.each.any? { |_id, attrs| attrs[:status] == 'pending' }
  end

  def render_pending_status_error
    @approvals = MonthlyApproval.pending.where(approver: current_user)
    flash.now[:alert] = '承認または否認を選択してください'
    render :index, layout: false, status: :unprocessable_entity
  end

  def process_bulk_update(selected_approvals)
    MonthlyApproval.transaction do
      selected_approvals.each do |id, attrs|
        approval = MonthlyApproval.find_by(id:, approver: current_user)
        next unless approval

        approval.update!(status: attrs[:status])
      end
    end
  end

  def handle_bulk_update_success
    flash[:success] = '承認処理が完了しました'
    redirect_to user_path(current_user)
  end

  def handle_bulk_update_error(error)
    @approvals = MonthlyApproval.pending.where(approver: current_user)
    flash.now[:alert] = "エラーが発生しました: #{error.message}"
    render :index, layout: false, status: :unprocessable_entity
  end
end
