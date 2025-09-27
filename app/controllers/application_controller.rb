class ApplicationController < ActionController::Base
  include SessionsHelper

  # テスト環境ではCSRF保護を無効化
  protect_from_forgery with: :exception, unless: -> { Rails.env.test? }

  # 曜日配列（定数）
  DAYS_OF_THE_WEEK = %w[日 月 火 水 木 金 土].freeze
end
