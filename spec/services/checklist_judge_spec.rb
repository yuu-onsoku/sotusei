require 'rails_helper'

RSpec.describe ChecklistJudge do
  describe ".items" do
    it "16項目読み込める" do
      expect(ChecklistJudge.items.size).to eq(16)
    end

    it "すべての項目に見出し・分類・説明がある" do
      ChecklistJudge.items.each do |item|
        expect(item["text"]).to be_present
        expect(item["category"]).to be_present
        expect(item["detail"]).to be_present
      end
    end

    it "カテゴリが5種類、YAMLの順番どおりに並んでいる" do
      categories = ChecklistJudge.items.map { |item| item["category"] }.uniq
      expect(categories).to eq([
        "毎日のお世話",
        "ねこの行動",
        "家や物への影響",
        "健康とお金",
        "暮らしと将来"
      ])
    end
  end

  describe "#total_count" do
    it "16項目あることを数えられる" do
      expect(ChecklistJudge.new([]).total_count).to eq(16)
    end
  end

  describe "#checked_count" do
    it "1つもチェックしないと0になる" do
      expect(ChecklistJudge.new([]).checked_count).to eq(0)
    end

    it "3つチェックすると3になる" do
      expect(ChecklistJudge.new([ "0", "3", "5" ]).checked_count).to eq(3)
    end

    it "存在しない番号は数に入らない" do
      expect(ChecklistJudge.new([ "0", "99" ]).checked_count).to eq(1)
    end
  end

  describe "#unchecked_items" do
    it "チェックしていない項目だけが残る" do
      all_but_first = (1..15).map(&:to_s)   # 0番だけチェックしない
      unchecked = ChecklistJudge.new(all_but_first).unchecked_items

      expect(unchecked.size).to eq(1)
      expect(unchecked.first["text"]).to eq(ChecklistJudge.items.first["text"])
    end

    it "1つもチェックしないと、16項目すべてが残る" do
      expect(ChecklistJudge.new([]).unchecked_items.size).to eq(16)
    end

    it "全部チェックすると、空になる" do
      all = (0..15).map(&:to_s)
      expect(ChecklistJudge.new(all).unchecked_items).to be_empty
    end
  end

  describe "#all_checked?" do
    it "全部チェックするとtrueになる" do
      all = (0..15).map(&:to_s)   # "0" から "15" までの16個
      expect(ChecklistJudge.new(all).all_checked?).to eq(true)
    end

    it "1つもチェックしないとfalseになる" do
      expect(ChecklistJudge.new([]).all_checked?).to eq(false)
    end

    it "1つでもチェック漏れがあるとfalseになる" do
      all_but_last = (0..14).map(&:to_s)   # 15番だけチェックしない
      expect(ChecklistJudge.new(all_but_last).all_checked?).to eq(false)
    end
  end
end
