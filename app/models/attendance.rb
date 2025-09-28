class Attendance < ApplicationRecord
  belongs_to :user

  validates :worked_on,
            presence: true,
            uniqueness: { scope: :user_id }

  validates :note, length: { maximum: 50 }

  validate :started_at_presence_when_finished_at_present
  validate :finished_at_after_started_at

  private

  def started_at_presence_when_finished_at_present
    return unless finished_at.present? && started_at.blank?

    errors.add(:started_at, "を入力してください")
  end

  def finished_at_after_started_at
    return unless started_at.present? && finished_at.present? && finished_at <= started_at

    errors.add(:finished_at, "は出勤時間より後にしてください")
  end
end
