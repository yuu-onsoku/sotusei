require 'rails_helper'

RSpec.describe Diagnosis, type: :model do
  it "必要な項目がそろっていれば有効" do
    expect(build(:diagnosis)).to be_valid
  end

  it "回答が無いと無効" do
    expect(build(:diagnosis, answers: {})).to be_invalid
  end

  describe "#judge" do
    # 回答を保存しているので、あとから判定し直せる。
    # コメント文を直したら、過去の履歴の表示も一緒に変わる。
    it "保存した回答から判定をやり直せる" do
      diagnosis = build(:diagnosis)

      expect(diagnosis.judge.result).to eq("準備万端")
      expect(diagnosis.judge.score).to eq(10)
    end

    it "弱かったカテゴリも取り出せる" do
      answers = { "0" => "2", "1" => "1", "2" => "1", "3" => "1", "4" => "2" }
      diagnosis = build(:diagnosis, answers: answers, score: -2, result: "今はまだ早い")

      expect(diagnosis.judge.weak_categories).to eq([ "生活リズム", "経済" ])
    end
  end

  it "ユーザーを削除すると履歴も消える" do
    user = create(:user)
    create(:diagnosis, user: user)

    expect { user.destroy }.to change(Diagnosis, :count).by(-1)
  end
end
