require 'rails_helper'

RSpec.describe DiagnosisJudge do
  describe ".simple_questions" do
    it "5問読み込める" do
      expect(DiagnosisJudge.simple_questions.size).to eq(5)
    end

    it "すべての質問に文章がある" do
      DiagnosisJudge.simple_questions.each do |q|
        expect(q["text"]).to be_present
      end
    end

    it "すべての選択肢に文章がある" do
      DiagnosisJudge.simple_questions.each do |q|
        q["choices"].each do |c|
          expect(c["text"]).to be_present
        end
      end
    end
  end

  describe "#score" do
    it "すべて最良を選ぶと10点になる" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).score).to eq(10)
    end

    it "すべて真ん中を選ぶと1点になる" do
      answers = { "0" => "1", "1" => "1", "2" => "1", "3" => "1", "4" => "1" }
      expect(DiagnosisJudge.new(answers).score).to eq(1)
    end
  end

  describe "#blocked?" do
    it "blockerを選んでいなければ false" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).blocked?).to be false
    end

    it "ペット不可の住宅を選ぶと true" do
      # 3問目（index 2）の3番目の選択肢（index 2）が blocker
      answers = { "0" => "0", "1" => "0", "2" => "2", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).blocked?).to be true
    end
  end

  describe "#result" do
    it "すべて最良なら準備万端" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).result).to eq("準備万端")
    end

    it "すべて真ん中なら成猫なら可能" do
      answers = { "0" => "1", "1" => "1", "2" => "1", "3" => "1", "4" => "1" }
      expect(DiagnosisJudge.new(answers).result).to eq("成猫なら可能")
    end

    it "blockerを選ぶと点数に関係なく今はまだ早い" do
      # 3問目だけ blocker、他は最良
      answers = { "0" => "0", "1" => "0", "2" => "2", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).result).to eq("今はまだ早い")
    end
  end
end
