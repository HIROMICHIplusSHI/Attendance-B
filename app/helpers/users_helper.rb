module UsersHelper
  # 基本時間表示用（10進数：7.50時間など）
  def format_basic_info(time)
    return "未設定" if time.nil?

    hour = time.hour
    min = time.min
    format("%.2f", hour + (min / 60.0))
  end
end
