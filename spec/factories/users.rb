FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "ユーザー#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    department { "開発部" }

    trait :manager do
      after(:create) do |user|
        # 部下を1人作成してmanager?がtrueになるようにする
        create(:user, manager: user)
      end
    end

    trait :admin do
      admin { true }
    end
  end
end
