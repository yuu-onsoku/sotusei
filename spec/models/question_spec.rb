require 'rails_helper'

RSpec.describe Question, type: :model do
  describe "バリデーション" do
    it "ファクトリのデフォルト値で有効になる" do
      question = build(:question)
      expect(question).to be_valid
    end

    describe "title" do
      it "空だと無効になる" do
        question = build(:question, title: "")
        expect(question).to be_invalid
        expect(question.errors[:title]).to include("を入力してください")
      end

      it "100文字ちょうどなら有効になる" do
        question = build(:question, title: "あ" * 100)
        expect(question).to be_valid
      end

      it "101文字だと無効になる" do
        question = build(:question, title: "あ" * 101)
        expect(question).to be_invalid
        expect(question.errors[:title]).to include("は100文字以内で入力してください")
      end
    end

    describe "content" do
      it "空だと無効になる" do
        question = build(:question, content: "")
        expect(question).to be_invalid
        expect(question.errors[:content]).to include("を入力してください")
      end

      it "5000文字ちょうどなら有効になる" do
        question = build(:question, content: "あ" * 5000)
        expect(question).to be_valid
      end

      it "5001文字だと無効になる" do
        question = build(:question, content: "あ" * 5001)
        expect(question).to be_invalid
      end
    end

    describe "category" do
      it "空だと無効になる" do
        question = build(:question, category: "")
        expect(question).to be_invalid
      end

      it "CATEGORIES に含まれる値ならすべて有効になる" do
        Question::CATEGORIES.each do |category|
          question = build(:question, category: category)
          expect(question).to be_valid
        end
      end

      it "CATEGORIES にない値だと無効になる" do
        question = build(:question, category: "ラーメン")
        expect(question).to be_invalid
        expect(question.errors[:category]).to include("は一覧にありません")
      end
    end

    it "user がないと無効になる" do
      question = build(:question, user: nil)
      expect(question).to be_invalid
    end
  end

  describe ".search" do
    # ① じゅんび：3つの質問をデータベースに用意しておく
    #    let! を使うと、どのテストが始まる前にも必ず作られる
    let!(:cat_question) { create(:question, title: "猫のごはんについて", content: "何をあげればいい？") }
    let!(:dog_question) { create(:question, title: "犬の散歩について", content: "毎日何分あるけばいい？") }
    let!(:english_question) { create(:question, title: "About Cat food", content: "What should I buy?") }

    it "タイトルにキーワードを含む質問が見つかる" do
      expect(Question.search("猫")).to include(cat_question)
      expect(Question.search("猫")).not_to include(dog_question)
    end

    it "本文にキーワードを含む質問が見つかる" do
      expect(Question.search("散歩")).to include(dog_question)
    end

    it "大文字と小文字が違っても見つかる" do
      # "CAT"（大文字）で探しても "Cat"（小文字まじり）が見つかる
      expect(Question.search("CAT")).to include(english_question)
    end

    it "どこにも無いキーワードだと1件も見つからない" do
      expect(Question.search("ラーメン")).to be_empty
    end

    it "キーワードが空文字なら全件かえってくる" do
      expect(Question.search("")).to match_array([ cat_question, dog_question, english_question ])
    end

    it "キーワードが nil なら全件かえってくる" do
      expect(Question.search(nil)).to match_array([ cat_question, dog_question, english_question ])
    end

    it "キーワードが空白だけなら全件かえってくる" do
      expect(Question.search("   ")).to match_array([ cat_question, dog_question, english_question ])
    end
  end
end
