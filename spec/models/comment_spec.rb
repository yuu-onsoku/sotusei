require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "バリデーション" do
    it "本文があれば有効" do
      expect(build(:comment)).to be_valid
    end

    it "本文が空だと無効" do
      expect(build(:comment, content: "")).to be_invalid
    end

    it "1000文字までは有効" do
      expect(build(:comment, content: "あ" * 1000)).to be_valid
    end

    it "1001文字だと無効" do
      expect(build(:comment, content: "あ" * 1001)).to be_invalid
    end
  end

  describe "コメントできる相手" do
    it "質問にコメントできる" do
      comment = create(:comment, :for_question)
      expect(comment.commentable_type).to eq("Question")
    end

    it "回答にコメントできる" do
      comment = create(:comment, :for_answer)
      expect(comment.commentable_type).to eq("Answer")
    end

    it "同じ人が同じ質問に何度でもコメントできる" do
      question = create(:question)
      user = create(:user)
      create(:comment, commentable: question, user: user)

      expect(build(:comment, commentable: question, user: user)).to be_valid
    end
  end

  describe "親が消えたとき" do
    it "質問を削除するとコメントも消える" do
      question = create(:question)
      create(:comment, commentable: question)

      expect { question.destroy }.to change(Comment, :count).by(-1)
    end
  end
end
