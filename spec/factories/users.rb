FactoryBot.define do
  factory :user do
    # username と email は一意制約があるので sequence で毎回違う値にする
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "テストユーザー" }
    password { "password123" }
  end
end
