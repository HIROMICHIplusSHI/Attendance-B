FactoryBot.define do
  factory :attendance do
    worked_on { Date.current }
    started_at { nil }
    finished_at { nil }
    note { nil }
    user

    trait :with_times do
      started_at { Time.zone.parse("#{worked_on} 09:00") }
      finished_at { Time.zone.parse("#{worked_on} 17:00") }
    end
  end
end
