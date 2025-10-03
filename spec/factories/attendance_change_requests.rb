FactoryBot.define do
  factory :attendance_change_request do
    attendance { nil }
    requester { nil }
    approver { nil }
    original_started_at { "2025-10-03 07:34:43" }
    original_finished_at { "2025-10-03 07:34:43" }
    requested_started_at { "2025-10-03 07:34:43" }
    requested_finished_at { "2025-10-03 07:34:43" }
    status { 1 }
  end
end
