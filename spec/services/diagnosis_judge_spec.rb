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
end
