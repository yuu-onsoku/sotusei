FactoryBot.define do
  factory :question do
    user                       # belongs_to :user → 関連する user も自動生成される
    sequence(:title) { |n| "猫のごはんについて#{n}" }
    content { "食欲がないのですが、どうすればいいでしょうか。" }
    category { Question::CATEGORIES.first }   # "食事"
  end
end
