class AttendanceChangeRequest < ApplicationRecord
  belongs_to :attendance
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User'

  validates :attendance, :requester, :approver, presence: true
  validates :requested_started_at, :requested_finished_at, presence: true

  enum status: { pending: 0, approved: 1, rejected: 2 }
end
