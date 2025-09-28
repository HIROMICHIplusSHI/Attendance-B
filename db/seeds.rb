# db/seeds.rb - 勤怠管理アプリのシードデータ

# 管理者ユーザー
admin_user = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "管理者"
  user.password = "password"
  user.password_confirmation = "password"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ 管理者ユーザー作成: #{admin_user.name} (#{admin_user.email})"

# テストユーザー（簡単ログイン用）
test_user = User.find_or_create_by!(email: "test@example.com") do |user|
  user.name = "テスト太郎"
  user.password = "password"
  user.password_confirmation = "password"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ テストユーザー作成: #{test_user.name} (#{test_user.email})"

# 一般ユーザー（10人程度）
10.times do |n|
  User.find_or_create_by!(email: "user#{n + 1}@example.com") do |u|
    u.name = "社員#{n + 1}"
    u.password = "password"
    u.password_confirmation = "password"
    u.basic_time = Time.zone.parse("08:00:00")
    u.work_time = Time.zone.parse("07:30:00")
  end
  print "."
end

puts "\n✅ 一般ユーザー10人作成完了"

puts "\n🎯 ログイン情報:"
puts "管理者: admin@example.com / password"
puts "テストユーザー: test@example.com / password"
puts "一般ユーザー: user1@example.com～user10@example.com / password"
