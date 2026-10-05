FactoryBot.define do
  factory :contact do
    name { "ねこ太郎" }
    sequence(:email) { |n| "contact#{n}@example.com" }
    content { "診断の結果について質問があります。" }
  end
end
