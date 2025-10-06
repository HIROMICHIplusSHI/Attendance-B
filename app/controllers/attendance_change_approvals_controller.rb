class AttendanceChangeApprovalsController < ApplicationController
  before_action :logged_in_user
  before_action :require_manager, only: %i[index bulk_update]

  def index
    @requests = AttendanceChangeRequest.pending.where(approver: current_user).includes(:requester, :attendance)

    return unless request.xhr?

    render layout: false
  end

  def bulk_update
    selected_requests = extract_selected_requests

    return render_no_selection_error if selected_requests.empty?
    return render_pending_status_error if pending_status?(selected_requests)

    process_bulk_update(selected_requests)
    handle_bulk_update_success
  rescue ActiveRecord::RecordInvalid => e
    handle_bulk_update_error(e)
  end

  private

  def require_manager
    return if current_user.manager?

    redirect_to root_path, alert: '管理者権限が必要です'
  end

  def extract_selected_requests
    request_params = params[:requests] || {}
    request_params.select { |_id, attrs| attrs[:selected] == '1' }
  end

  def render_no_selection_error
    @requests = AttendanceChangeRequest.pending.where(approver: current_user).includes(:requester, :attendance)
    flash.now[:alert] = '承認する項目を選択してください'
    render :index, layout: false, status: :unprocessable_entity
  end

  def pending_status?(selected_requests)
    selected_requests.any? { |_id, attrs| attrs[:status] == 'pending' }
  rescue NoMethodError
    # ActionController::Parametersの場合
    selected_requests.each.any? { |_id, attrs| attrs[:status] == 'pending' }
  end

  def render_pending_status_error
    @requests = AttendanceChangeRequest.pending.where(approver: current_user).includes(:requester, :attendance)
    flash.now[:alert] = '承認または否認を選択してください'
    render :index, layout: false, status: :unprocessable_entity
  end

  def process_bulk_update(selected_requests)
    AttendanceChangeRequest.transaction do
      selected_requests.each do |id, attrs|
        request_record = AttendanceChangeRequest.find_by(id:, approver: current_user)
        next unless request_record

        request_record.update!(status: attrs[:status])

        # 承認された場合は勤怠データを更新
        next unless attrs[:status] == 'approved'

        request_record.attendance.update!(
          started_at: request_record.requested_started_at,
          finished_at: request_record.requested_finished_at,
          note: request_record.change_reason
        )
      end
    end
  end

  def handle_bulk_update_success
    flash[:success] = '承認処理が完了しました'
    redirect_to user_path(current_user)
  end

  def handle_bulk_update_error(error)
    @requests = AttendanceChangeRequest.pending.where(approver: current_user).includes(:requester, :attendance)
    flash.now[:alert] = "エラーが発生しました: #{error.message}"
    render :index, layout: false, status: :unprocessable_entity
  end
end
