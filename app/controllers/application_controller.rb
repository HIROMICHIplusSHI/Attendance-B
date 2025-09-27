class ApplicationController < ActionController::Base
  include SessionsHelper

  # テスト環境ではCSRF保護を無効化
  protect_from_forgery with: :exception, unless: -> { Rails.env.test? }
end
