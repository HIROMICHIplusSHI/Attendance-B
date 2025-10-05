FactoryBot.define do
  factory :monthly_approval do
    association :user
    association :approver, factory: :user
    target_month { Date.today.beginning_of_month }
    status { :pending }
    approved_at { nil }
  end
end
