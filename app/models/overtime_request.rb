class OvertimeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: 'User'

  validates :user, :approver, :worked_on, presence: true
  validates :estimated_end_time, :business_content, presence: true

  enum status: { pending: 0, approved: 1, rejected: 2 }
end
