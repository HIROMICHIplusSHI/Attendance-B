module SessionsHelper
  # ユーザーをログインする
  def log_in(user)
    session[:user_id] = user.id
  end

  # 現在ログイン中のユーザーを返す
  def current_user
    return unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
  end

  # ユーザーがログイン済みかどうかを判定
  def logged_in?
    !current_user.nil?
  end

  # ユーザーをログアウトする
  def log_out
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
