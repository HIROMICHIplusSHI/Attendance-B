# frozen_string_literal: true

class ApplicationRequestsController < ApplicationController
  before_action :logged_in_user
  before_action :set_attendance

  def new
    # モーダル表示用（AJAX対応）
    render layout: false
  end

  def create
    @params = params[:application_request]
    @errors = []

    validate_inputs
    return render_with_errors if @errors.any?

    request.xhr? ? handle_ajax_create : handle_normal_create
  end

  private

  def set_attendance
    @attendance = Attendance.find(params[:attendance_id])
  end

  def validate_inputs
    @errors << "承認者を選択してください" if @params[:approver_id].blank?
    validate_attendance_change
    validate_overtime_request
    validate_at_least_one_input
  end

  def validate_attendance_change
    params = [@params[:requested_started_at], @params[:requested_finished_at], @params[:change_reason]]
    filled = params.any?(&:present?)
    complete = params.all?(&:present?)

    return unless filled && !complete

    @errors << "勤怠変更申請は出勤時間、退勤時間、変更理由を全て入力してください"
  end

  def validate_overtime_request
    params = [@params[:estimated_end_time], @params[:business_content]]
    filled = params.any?(&:present?)
    complete = params.all?(&:present?)

    @errors << "残業申請は終了予定時間と業務内容を両方入力してください" if filled && !complete
  end

  def validate_at_least_one_input
    attendance_filled = [@params[:requested_started_at], @params[:requested_finished_at],
                         @params[:change_reason]].any?(&:present?)
    overtime_filled = [@params[:estimated_end_time], @params[:business_content]].any?(&:present?)

    @errors << "勤怠変更か残業申請のいずれかを入力してください" unless attendance_filled || overtime_filled
  end

  def render_with_errors
    log_error_with_context('申請フォーム入力エラー',
                           { attendance: { id: @attendance.id, worked_on: @attendance.worked_on },
                             errors: @errors })

    flash.now[:danger] = @errors.join("<br>").html_safe
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity, layout: request.xhr? ? false : 'application' }
      format.json { render_error_json(@errors) }
    end
  end

  def create_attendance_change_request
    params = [@params[:requested_started_at], @params[:requested_finished_at], @params[:change_reason]]
    return false unless params.all?(&:present?)

    AttendanceChangeRequest.create!(
      attendance: @attendance,
      requester: @attendance.user,
      approver_id: @params[:approver_id],
      original_started_at: @attendance.started_at,
      original_finished_at: @attendance.finished_at,
      requested_started_at: parse_time_param(@params[:requested_started_at]),
      requested_finished_at: parse_time_param(@params[:requested_finished_at]),
      change_reason: @params[:change_reason],
      status: :pending
    )
    true
  end

  def create_overtime_request
    params = [@params[:estimated_end_time], @params[:business_content]]
    return false unless params.all?(&:present?)

    OvertimeRequest.create!(
      user: @attendance.user,
      approver_id: @params[:approver_id],
      worked_on: @attendance.worked_on,
      estimated_end_time: parse_time_param(@params[:estimated_end_time]),
      business_content: @params[:business_content],
      status: :pending
    )
    true
  end

  def build_success_message(messages)
    return "勤怠変更と残業申請を送信しました" if messages.size == 2

    "#{messages.first}を送信しました"
  end

  def parse_time_param(time_string)
    return nil if time_string.blank?

    # "09:30"形式の文字列をTimeオブジェクトに変換
    Time.zone.parse(time_string)
  end

  def handle_ajax_create
    # Ajaxリクエスト時はバリデーションのみ（保存しない）
    head :ok
  end

  def handle_normal_create
    # 通常リクエスト時に実際に保存
    success_messages = []
    success_messages << "勤怠変更申請" if create_attendance_change_request
    success_messages << "残業申請" if create_overtime_request

    flash[:success] = build_success_message(success_messages)
    redirect_to user_path(@attendance.user)
  end
end
