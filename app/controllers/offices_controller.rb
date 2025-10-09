class OfficesController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user
  before_action :set_office, only: %i[edit update destroy]

  def index
    @offices = Office.all.order(:office_number)
  end

  def new
    @office = Office.new
    @office.office_number = generate_office_number
    respond_to do |format|
      format.html { render layout: false if request.xhr? }
    end
  end

  def create
    @office = Office.new(office_params)
    @office.office_number = generate_office_number

    request.xhr? ? handle_ajax_create : handle_normal_create
  end

  def edit
    respond_to do |format|
      format.html { render layout: false if request.xhr? }
    end
  end

  def update
    request.xhr? ? handle_ajax_update : handle_normal_update
  end

  def destroy
    @office.destroy
    flash[:success] = '拠点情報を削除しました'
    redirect_to offices_path
  end

  private

  def set_office
    @office = Office.find(params[:id])
  end

  def office_params
    params.require(:office).permit(:name, :attendance_type)
  end

  def generate_office_number
    last_office = Office.order(:office_number).last
    last_office ? last_office.office_number + 1 : 1
  end

  def handle_ajax_create
    if @office.valid?
      head :ok
    else
      flash.now[:danger] = @office.errors.full_messages.join('<br>').html_safe
      render :new, layout: false, status: :unprocessable_entity
    end
  end

  def handle_normal_create
    if @office.save
      flash[:success] = '拠点情報を追加しました'
      redirect_to offices_path
    else
      flash.now[:danger] = @office.errors.full_messages.join('<br>').html_safe
      render :new, layout: false, status: :unprocessable_entity
    end
  end

  def handle_ajax_update
    @office.assign_attributes(office_params)
    if @office.valid?
      head :ok
    else
      flash.now[:danger] = @office.errors.full_messages.join('<br>').html_safe
      render :edit, layout: false, status: :unprocessable_entity
    end
  end

  def handle_normal_update
    if @office.update(office_params)
      flash[:success] = '拠点情報を更新しました'
      redirect_to offices_path
    else
      flash.now[:danger] = @office.errors.full_messages.join('<br>').html_safe
      render :edit, layout: false, status: :unprocessable_entity
    end
  end
end
