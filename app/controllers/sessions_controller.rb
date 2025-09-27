class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      log_in user
      flash[:success] = 'ログインしました'
      redirect_to user
    else
      flash.now[:danger] = 'メールアドレスまたはパスワードが正しくありません'
      render 'new'
    end
  end

  def destroy
    log_out
    flash[:info] = 'ログアウトしました'
    redirect_to root_url
  end
end
