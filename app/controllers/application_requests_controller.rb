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
    validate_overtime_request
  end

  def validate_overtime_request
    return unless @params[:estimated_end_time].blank? || @params[:business_content].blank?

    @errors << "終了予定時間と業務内容を両方入力してください"
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

  def create_overtime_request
    OvertimeRequest.create!(
      user: @attendance.user,
      approver_id: @params[:approver_id],
      worked_on: @attendance.worked_on,
      estimated_end_time: parse_time_param(@params[:estimated_end_time]),
      business_content: @params[:business_content],
      status: :pending
    )
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
    create_overtime_request
    flash[:success] = "残業申請を送信しました"
    redirect_to user_path(@attendance.user)
  end
end
