require 'rails_helper'

  RSpec.describe Like, type: :model do
    it "ファクトリのデフォルト値で有効になる" do
      expect(build(:like)).to be_valid
    end

    it "userがないと無効になる" do
      like = build(:like, user: nil)
      expect(like).to be_invalid
    end

    it "likeableがないと無効になる" do
      like = build(:like, likeable: nil)
      expect(like).to be_invalid
    end

    describe "同じ対象へのいいねは1人1回まで" do
     it "同じユーザーが同じ質問に2回いいねすると無効になる" do
      user = create(:user)              # 人を1人つくる
      question = create(:question)      # 質問を1つつくる

      create(:like, user: user, likeable: question)        # 1回目（名簿に書く）

      second = build(:like, user: user, likeable: question) # 2回目（同じ人・同じ質問）
      expect(second).to be_invalid                          # ダメなはず
    end

    it "別のユーザーなら同じ質問にいいねできる" do
      question = create(:question)          # 同じ質問を1つ用意
      create(:like, likeable: question)     # 1人目がいいね（名簿に書く）

      another = build(:like, likeable: question)   # 2人目がいいね
      expect(another).to be_valid                  # OKなはず
    end

    it "同じユーザーでも別の質問ならいいねできる" do
      user = create(:user)
      question1 = create(:question)
      question2 = create(:question)

      create(:like, user: user, likeable: question1)

      other = build(:like, user: user, likeable: question2)   # ← 書き足した1行目
      expect(other).to be_valid                               # ← 書き足した2行目
    end
  end
end
