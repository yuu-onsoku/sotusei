FactoryBot.define do
  factory :answer do
    question
    user
    content { "うちの子も同じでした。まずは動物病院で相談するのがおすすめです。" }
  end
end
