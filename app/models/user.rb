class User < ApplicationRecord
  attr_accessor :remember_token

  has_many :attendances, dependent: :destroy
  has_secure_password validations: false

  # 組織階層
  belongs_to :manager, class_name: 'User', optional: true
  has_many :subordinates, class_name: 'User', foreign_key: :manager_id

  # 承認申請
  has_many :monthly_approvals, dependent: :destroy
  has_many :attendance_change_requests, foreign_key: :requester_id, dependent: :destroy
  has_many :overtime_requests, dependent: :destroy

  # 権限管理
  enum role: { employee: 0, manager: 1, admin: 2 }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, allow_blank: true, on: :update
  validates :department, length: { maximum: 50 }, allow_blank: true
  validates :basic_time, :work_time, presence: true
  validates :employee_number, uniqueness: true, allow_blank: true
  validates :card_id, uniqueness: { allow_nil: true }
  validates :scheduled_start_time, presence: true, if: -> { scheduled_end_time.present? }
  validates :scheduled_end_time, presence: true, if: -> { scheduled_start_time.present? }
  validate :scheduled_times_logical_order

  before_save { self.email = email.downcase }
  before_save :normalize_blank_fields

  # ランダムなトークンを返す
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # 渡された文字列のハッシュ値を返す
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost:)
  end

  # 永続セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    return false if remember_digest.nil?

    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # 承認権限チェック
  def can_approve?
    manager?
  end

  private

  def normalize_blank_fields
    # 空文字を nil に変換してユニーク制約エラーを防ぐ
    self.employee_number = nil if employee_number.blank?
    self.scheduled_start_time = nil if scheduled_start_time.blank?
    self.scheduled_end_time = nil if scheduled_end_time.blank?
  end

  def scheduled_times_logical_order
    return if scheduled_start_time.blank? || scheduled_end_time.blank?

    return unless scheduled_end_time <= scheduled_start_time

    errors.add(:scheduled_end_time, 'は開始時間より後に設定してください')
  end
end
