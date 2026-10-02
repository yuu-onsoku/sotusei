FactoryBot.define do
  factory :comment do
    user
    content { "うちの子もそうでした。参考になります。" }
    for_question   # デフォルトの commentable を決めておく

    trait :for_question do
      association :commentable, factory: :question
    end

    trait :for_answer do
      association :commentable, factory: :answer
    end
  end
end
