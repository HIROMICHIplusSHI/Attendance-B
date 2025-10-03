FactoryBot.define do
  factory :monthly_approval do
    user { nil }
    approver { nil }
    target_month { "2025-10-03" }
    status { 1 }
    approved_at { "2025-10-03 07:34:13" }
  end
end
