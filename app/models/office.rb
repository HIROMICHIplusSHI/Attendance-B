class Office < ApplicationRecord
  validates :office_number, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 50 }
  validates :attendance_type, presence: true
end
