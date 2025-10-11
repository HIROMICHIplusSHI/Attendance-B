class WorkingEmployeesController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  def index
    @working_employees = Attendance
                         .includes(:user)
                         .where(worked_on: Date.today)
                         .where.not(started_at: nil)
                         .where(finished_at: nil)
                         .order('users.employee_number')
  end
end
