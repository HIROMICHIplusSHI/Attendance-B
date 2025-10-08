# db/seeds.rb - 勤怠管理アプリのシードデータ

# 管理者ユーザー（勤怠機能なし）
admin_user = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "管理者"
  user.password = "password"
  user.password_confirmation = "password"
  user.role = :admin
  user.employee_number = "A00001"
  user.department = "総務部"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ 管理者ユーザー作成: #{admin_user.name} (#{admin_user.email}) [#{admin_user.role}]"

# 上長ユーザー（勤怠 + 承認機能）
manager1 = User.find_or_create_by!(email: "manager1@example.com") do |user|
  user.name = "上長A"
  user.password = "password"
  user.password_confirmation = "password"
  user.role = :manager
  user.employee_number = "M00001"
  user.department = "開発部"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ 上長ユーザー作成: #{manager1.name} (#{manager1.email}) [#{manager1.role}]"

manager2 = User.find_or_create_by!(email: "manager2@example.com") do |user|
  user.name = "上長B"
  user.password = "password"
  user.password_confirmation = "password"
  user.role = :manager
  user.employee_number = "M00002"
  user.department = "営業部"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ 上長ユーザー作成: #{manager2.name} (#{manager2.email}) [#{manager2.role}]"

# テストユーザー（簡単ログイン用・一般社員）
test_user = User.find_or_create_by!(email: "test@example.com") do |user|
  user.name = "テスト太郎"
  user.password = "password"
  user.password_confirmation = "password"
  user.role = :employee
  user.employee_number = "E00001"
  user.department = "開発部"
  user.basic_time = Time.zone.parse("08:00:00")
  user.work_time = Time.zone.parse("07:30:00")
end

puts "✅ テストユーザー作成: #{test_user.name} (#{test_user.email}) [#{test_user.role}]"

# 一般ユーザー（50人）- ページネーションテスト用
departments = %w[開発部 営業部 総務部 人事部 経理部 マーケティング部]
50.times do |n|
  User.find_or_create_by!(email: "user#{n + 1}@example.com") do |u|
    u.name = "社員#{n + 1}"
    u.password = "password"
    u.password_confirmation = "password"
    u.role = :employee
    u.employee_number = format("E%05d", n + 2)  # E00002から開始
    u.department = departments[n % departments.length]
    u.basic_time = Time.zone.parse("08:00:00")
    u.work_time = Time.zone.parse("07:30:00")
  end
  print "."
end

puts "\n✅ 一般ユーザー50人作成完了"

puts "\n🎯 ログイン情報:"
puts "管理者: admin@example.com / password"
puts "上長: manager1@example.com, manager2@example.com / password"
puts "テストユーザー: test@example.com / password"
puts "一般ユーザー: user1@example.com～user50@example.com / password"
puts "\n📊 データ統計:"
puts "総ユーザー数: #{User.count}名"
puts "管理者: #{User.admin.count}名"
puts "上長: #{User.manager.count}名"
puts "一般社員: #{User.employee.count}名"
puts "ページネーション: #{(User.count / 20.0).ceil}ページ（20件/ページ）"
