FactoryBot.define do
  factory :like do
    user
    for_question   # デフォルトの likeable を決めておく

    trait :for_question do
      association :likeable, factory: :question
    end

    trait :for_answer do
      association :likeable, factory: :answer
    end
  end
end
