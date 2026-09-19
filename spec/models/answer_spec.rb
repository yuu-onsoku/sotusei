require 'rails_helper'

RSpec.describe Answer, type: :model do
  describe "content" do
    it "空だと無効になる" do
      answer = build(:answer, content: "")
      expect(answer).to be_invalid
    end

    it "5000文字ちょうどなら有効になる" do
      answer = build(:answer, content: "あ" * 5000)
      expect(answer).to be_valid
    end

    it "5001文字だと無効になる" do
      answer = build(:answer, content: "あ" * 5001)
      expect(answer).to be_invalid
    end
  end

  it "questionがないと無効になる" do
    answer = build(:answer, question: nil)
    expect(answer).to be_invalid
  end

  it "userがないと無効になる" do
    answer = build(:answer, user: nil)
    expect(answer).to be_invalid
  end

  describe "画像の添付" do
    it "画像でないファイルは無効になる" do
      answer = build(:answer)
      answer.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/not_image.txt")),
        filename: "not_image.txt",
        content_type: "text/plain"
      )

      expect(answer).to be_invalid
    end
  end
end
