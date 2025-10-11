class MonthlyApproval < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: 'User'

  validates :user, :approver, :target_month, presence: true
  validates :target_month, uniqueness: { scope: :user_id }
  validate :attendance_data_exists

  enum status: { pending: 0, approved: 1, rejected: 2 }

  def approve!
    update!(status: :approved, approved_at: Time.current)
  end

  private

  def attendance_data_exists
    return unless user && target_month

    first_day = target_month.beginning_of_month
    last_day = target_month.end_of_month

    worked_days = user.attendances
                      .where(worked_on: first_day..last_day)
                      .where.not(started_at: nil)
                      .count

    return unless worked_days.zero?

    errors.add(:base, '勤怠データが登録されていません。出勤・退勤を登録してから申請してください。')
  end
end
