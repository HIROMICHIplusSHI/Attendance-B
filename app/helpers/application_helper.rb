module ApplicationHelper
  # 所属長承認申請の件数
  def monthly_approvals_count
    return 0 unless current_user&.manager?

    MonthlyApproval.pending.where(approver: current_user).count
  end

  # 勤怠変更申請の件数
  def attendance_change_requests_count
    return 0 unless current_user&.manager?

    AttendanceChangeRequest.pending.where(approver: current_user).count
  end

  # 残業申請の件数
  def overtime_requests_count
    return 0 unless current_user&.manager?

    OvertimeRequest.pending.where(approver: current_user).count
  end
end
