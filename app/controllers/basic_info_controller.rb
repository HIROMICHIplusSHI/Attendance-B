class BasicInfoController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  def index
    # 将来の実装用（システム全体の基本情報設定）
  end
end
