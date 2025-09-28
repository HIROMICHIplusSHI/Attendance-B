class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_secure_password validations: false

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, allow_blank: true, on: :update
  validates :department, length: { maximum: 50 }, allow_blank: true
  validates :basic_time, :work_time, presence: true

  before_save { self.email = email.downcase }
end
