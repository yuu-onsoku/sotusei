FactoryBot.define do
  factory :diagnosis do
    user
    answers { { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" } }
    score { 10 }
    result { "準備万端" }
  end
end
