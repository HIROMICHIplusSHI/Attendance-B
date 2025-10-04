class MonthlyApproval < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: 'User'

  validates :user, :approver, :target_month, presence: true
  validates :target_month, uniqueness: { scope: :user_id }

  enum status: { pending: 0, approved: 1, rejected: 2 }

  def approve!
    update!(status: :approved, approved_at: Time.current)
  end
end
