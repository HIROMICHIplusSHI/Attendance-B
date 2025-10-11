FactoryBot.define do
  factory :office do
    sequence(:office_number)
    name { "東京本社" }
    attendance_type { "出勤" }
  end
end
