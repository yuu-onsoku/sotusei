require 'rails_helper'

 RSpec.describe Answer, type: :model do   # 何をテストするか
    describe "content" do                       # グループ分け（入れ子にできる）
     it "空だと無効になる" do                  # テスト1本＝it
       answer = build(:answer, content: "")  # 準備
       expect(answer).to be_invalid          # 検証
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
  end
