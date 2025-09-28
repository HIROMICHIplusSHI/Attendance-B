FactoryBot.define do
  factory :attendance do
    worked_on { "2025-09-27" }
    started_at { "2025-09-27 13:13:14" }
    finished_at { "2025-09-27 13:13:14" }
    note { "MyString" }
    user { nil }
  end
end
