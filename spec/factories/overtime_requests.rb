FactoryBot.define do
  factory :overtime_request do
    user { nil }
    approver { nil }
    worked_on { "2025-10-03" }
    estimated_end_time { "2025-10-03 07:34:52" }
    business_content { "MyText" }
    next_day_flag { false }
    status { 1 }
  end
end
