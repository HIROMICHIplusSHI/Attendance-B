# db/seeds.rb - 勤怠管理アプリのシードデータ（本番環境用）

# 既存データをクリア
puts "⚠️  既存データをクリアします..."
MonthlyApproval.destroy_all
OvertimeRequest.destroy_all
AttendanceChangeRequest.destroy_all
Attendance.destroy_all
User.destroy_all
puts "✅ データクリア完了"

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

# 上長ユーザー（5名）
managers = []
manager_departments = %w[開発部 営業部 総務部 人事部 マーケティング部]

5.times do |i|
  manager = User.find_or_create_by!(email: "manager#{i + 1}@example.com") do |user|
    user.name = "上長#{('A'.ord + i).chr}"
    user.password = "password"
    user.password_confirmation = "password"
    user.role = :manager
    user.employee_number = format("M%05d", i + 1)
    user.department = manager_departments[i]
    user.basic_time = Time.zone.parse("08:00:00")
    user.work_time = Time.zone.parse("07:30:00")
    user.scheduled_start_time = Time.zone.parse("09:00:00")
    user.scheduled_end_time = Time.zone.parse("18:00:00")
  end
  managers << manager
  puts "✅ 上長ユーザー作成: #{manager.name} (#{manager.email}) [#{manager.role}]"
end

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
  user.scheduled_start_time = Time.zone.parse("09:00:00")
  user.scheduled_end_time = Time.zone.parse("18:00:00")
end

puts "✅ テストユーザー作成: #{test_user.name} (#{test_user.email}) [#{test_user.role}]"

# 一般ユーザー（40人） - 各上長に8人ずつ配置
employees = []
departments = %w[開発部 営業部 総務部 人事部 経理部 マーケティング部]

40.times do |n|
  employee = User.find_or_create_by!(email: "employee#{n + 1}@example.com") do |u|
    u.name = "社員#{format('%02d', n + 1)}"
    u.password = "password"
    u.password_confirmation = "password"
    u.role = :employee
    u.employee_number = format("E%05d", n + 2) # E00002から開始
    u.department = departments[n % departments.length]
    u.basic_time = Time.zone.parse("08:00:00")
    u.work_time = Time.zone.parse("07:30:00")
    u.scheduled_start_time = Time.zone.parse("09:00:00")
    u.scheduled_end_time = Time.zone.parse("18:00:00")
  end
  employees << employee
  print "."
end

puts "\n✅ 一般ユーザー40人作成完了"

# 10月分の勤怠データ作成
puts "\n📅 10月分の勤怠データを作成中..."

october_start = Date.new(2025, 10, 1)
october_end = Date.new(2025, 10, 31)
all_users = [test_user] + managers + employees

all_users.each do |user|
  (october_start..october_end).each do |date|
    # 土日はスキップ
    next if date.saturday? || date.sunday?

    # ランダムで出勤パターンを作成
    pattern = rand(10)

    case pattern
    when 0..8 # 通常勤務（90%）
      user.attendances.create!(
        worked_on: date,
        started_at: Time.zone.parse("#{date} 09:00"),
        finished_at: Time.zone.parse("#{date} 18:00"),
        note: nil
      )
    when 9 # 早退（10%）
      user.attendances.create!(
        worked_on: date,
        started_at: Time.zone.parse("#{date} 09:00"),
        finished_at: Time.zone.parse("#{date} 15:00"),
        note: "早退"
      )
    end
  end
  print "."
end

puts "\n✅ 10月分の勤怠データ作成完了"

# 承認申請のサンプルデータ作成
puts "\n📝 承認申請データを作成中..."

# 提出用アカウントの承認申請データ（必須）
puts "📌 提出用アカウントの申請データを作成中..."

# テストユーザー（一般社員）の申請
test_approver = managers[0] # manager1を承認者に
worked_days = (october_start..october_end).to_a.reject { |d| d.saturday? || d.sunday? }

# 月次承認申請（保留中）
MonthlyApproval.create!(
  user: test_user,
  approver: test_approver,
  target_month: october_start,
  status: :pending
)

# 残業申請（承認済み1件、保留中1件）
OvertimeRequest.create!(
  user: test_user,
  approver: test_approver,
  worked_on: worked_days[10], # 10月中旬
  estimated_end_time: Time.zone.parse("#{worked_days[10]} 21:00"),
  business_content: "システム開発のため",
  next_day_flag: false,
  status: :approved
)

OvertimeRequest.create!(
  user: test_user,
  approver: test_approver,
  worked_on: worked_days[15],
  estimated_end_time: Time.zone.parse("#{worked_days[15]} 20:00"),
  business_content: "プレゼン資料作成のため",
  next_day_flag: false,
  status: :pending
)

# 上長1（manager1）の申請
manager1_approver = managers[1] # manager2を承認者に

MonthlyApproval.create!(
  user: managers[0],
  approver: manager1_approver,
  target_month: october_start,
  status: :pending
)

OvertimeRequest.create!(
  user: managers[0],
  approver: manager1_approver,
  worked_on: worked_days[12],
  estimated_end_time: Time.zone.parse("#{worked_days[12]} 22:00"),
  business_content: "月末処理のため",
  next_day_flag: false,
  status: :approved
)

# 上長2（manager2）の申請
manager2_approver = managers[2] # manager3を承認者に

MonthlyApproval.create!(
  user: managers[1],
  approver: manager2_approver,
  target_month: october_start,
  status: :approved
)

OvertimeRequest.create!(
  user: managers[1],
  approver: manager2_approver,
  worked_on: worked_days[8],
  estimated_end_time: Time.zone.parse("#{worked_days[8]} 21:30"),
  business_content: "顧客対応のため",
  next_day_flag: false,
  status: :pending
)

puts "✅ 提出用アカウント申請データ作成完了"
puts "  ├─ test@example.com: 月次申請1件、残業申請2件"
puts "  ├─ manager1@example.com: 月次申請1件、残業申請1件"
puts "  └─ manager2@example.com: 月次申請1件、残業申請1件"

# 月次承認申請（一部承認済み、一部保留中）
sample_employees = employees.sample(10)
sample_employees.each_with_index do |employee, idx|
  approver = managers.sample
  status = idx < 5 ? :approved : :pending

  MonthlyApproval.create!(
    user: employee,
    approver:,
    target_month: october_start,
    status:
  )
end

puts "✅ 月次承認申請 10件作成（承認済み: 5件、保留中: 5件）"

# 勤怠変更申請（サンプル）
sample_attendances = Attendance.where(user: employees.sample(5)).limit(5)
sample_attendances.each_with_index do |attendance, idx|
  approver = managers.sample
  status = idx < 3 ? :approved : :pending

  AttendanceChangeRequest.create!(
    attendance:,
    requester: attendance.user,
    approver:,
    original_started_at: attendance.started_at,
    original_finished_at: attendance.finished_at,
    requested_started_at: attendance.started_at + 1.hour,
    requested_finished_at: attendance.finished_at + 1.hour,
    change_reason: "打刻修正依頼",
    status:
  )
end

puts "✅ 勤怠変更申請 5件作成（承認済み: 3件、保留中: 2件）"

# 残業申請（サンプル）
sample_employees.sample(8).each_with_index do |employee, idx|
  approver = managers.sample
  status = idx < 4 ? :approved : :pending
  worked_on = (october_start..october_end).to_a.reject { |d| d.saturday? || d.sunday? }.sample

  OvertimeRequest.create!(
    user: employee,
    approver:,
    worked_on:,
    estimated_end_time: Time.zone.parse("#{worked_on} 21:00"),
    business_content: "#{%w[システム開発 プレゼン資料作成 月末処理 顧客対応].sample}のため",
    next_day_flag: false,
    status:
  )
end

puts "✅ 残業申請 8件作成（承認済み: 4件、保留中: 4件）"

# 統計情報表示
puts "\n#{'=' * 60}"
puts "🎯 ログイン情報:"
puts "=" * 60
puts "管理者   : admin@example.com / password"
puts "上長     : manager1@example.com / password"
puts "一般社員 : test@example.com / password"
puts "         : employee1@example.com / password"
puts "\n📊 データ統計:"
puts "=" * 60
puts "総ユーザー数        : #{User.count}名"
puts "  ├─ 管理者         : #{User.admin.count}名"
puts "  ├─ 上長           : #{User.manager.count}名"
puts "  └─ 一般社員       : #{User.employee.count}名"
puts "勤怠レコード        : #{Attendance.count}件"
puts "月次承認申請        : #{MonthlyApproval.count}件"
puts "  ├─ 承認済み       : #{MonthlyApproval.approved.count}件"
puts "  └─ 保留中         : #{MonthlyApproval.pending.count}件"
puts "勤怠変更申請        : #{AttendanceChangeRequest.count}件"
puts "残業申請            : #{OvertimeRequest.count}件"
puts "ページネーション    : #{(User.count / 20.0).ceil}ページ（20件/ページ）"
puts "=" * 60
puts "✅ シードデータ作成完了！"
puts "=" * 60
