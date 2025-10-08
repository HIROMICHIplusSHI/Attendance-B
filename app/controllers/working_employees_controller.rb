class WorkingEmployeesController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  def index
    # 将来の実装用（feature/34で実装予定）
  end
end
