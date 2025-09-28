module SessionsHelper
  # ユーザーをログインする
  def log_in(user)
    session[:user_id] = user.id
  end

  # ユーザーを永続的にセッションに記憶する
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # 現在ログイン中のユーザーを返す
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # ユーザーがログイン済みかどうかを判定
  def logged_in?
    !current_user.nil?
  end

  # 永続的セッションを破棄する
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # ユーザーをログアウトする
  def log_out
    forget(current_user) if logged_in?
    session.delete(:user_id)
    @current_user = nil
  end

  # 引数のユーザーが現在ログイン中のユーザーと同じかどうかを判定
  def current_user?(user)
    user == current_user
  end

  # アクセス先のURLを保存する
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  # 保存されたURLまたはデフォルトURLにリダイレクト
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
end
