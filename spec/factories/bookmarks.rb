FactoryBot.define do
  factory :bookmark do
    user
    association :bookmarkable, factory: :post
  end
end
