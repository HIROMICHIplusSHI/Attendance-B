class SessionsController < ApplicationController
  def new; end

  def create
    user = find_user
    if authenticate_user(user)
      successful_login(user)
    else
      failed_login
    end
  end

  def destroy
    log_out
    flash[:info] = 'ログアウトしました'
    redirect_to root_url
  end

  private

  def find_user
    User.find_by(email: params[:session][:email].downcase)
  end

  def authenticate_user(user)
    user&.authenticate(params[:session][:password])
  end

  def successful_login(user)
    log_in user
    params[:session][:remember_me] == '1' ? remember(user) : forget(user)
    flash[:success] = 'ログインしました'

    # 管理者はユーザー一覧へ、それ以外は勤怠ページへ
    if user.admin?
      redirect_to users_path
    else
      redirect_to user
    end
  end

  def failed_login
    flash.now[:danger] = 'メールアドレスまたはパスワードが正しくありません'
    render 'new'
  end
end
