FactoryBot.define do
  factory :post do
    user
    content { "今日もよく寝ています。" }

    # 写真は1枚以上が必須なので、ファクトリで最初から添付しておく
    after(:build) do |post|
      post.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "test_image.png",
        content_type: "image/png"
      )
    end
  end
end
