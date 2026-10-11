require 'rails_helper'

# 入力はテキスト欄1つなので「人がどう打ってくるか分からない」をこのクラスが引き受ける。
# だから、きれいな入力よりも汚い入力のほうを厚くテストする。
RSpec.describe TagList do
  describe ".parse" do
    it "カンマで区切って配列にする" do
      expect(TagList.parse("三毛猫,子猫,寝顔")).to eq([ "三毛猫", "子猫", "寝顔" ])
    end

    it "読点や全角カンマでも区切れる" do
      expect(TagList.parse("三毛猫、子猫")).to eq([ "三毛猫", "子猫" ])
      expect(TagList.parse("三毛猫，子猫")).to eq([ "三毛猫", "子猫" ])
    end

    it "前後の空白を取る" do
      expect(TagList.parse(" 三毛猫 , 子猫 ")).to eq([ "三毛猫", "子猫" ])
    end

    # Ruby の strip は全角スペースを取らないので、ここを間違えると
    # 「　三毛猫」と「三毛猫」が別のタグとして登録されてしまう
    it "全角スペースも取る" do
      expect(TagList.parse("　三毛猫　,　子猫")).to eq([ "三毛猫", "子猫" ])
    end

    it "先頭の # と ＃ を取る" do
      expect(TagList.parse("#三毛猫,＃子猫")).to eq([ "三毛猫", "子猫" ])
    end

    it "# のあとに空白があっても取る" do
      expect(TagList.parse("# 三毛猫")).to eq([ "三毛猫" ])
    end

    it "空の項目を捨てる" do
      expect(TagList.parse("三毛猫,,子猫,")).to eq([ "三毛猫", "子猫" ])
    end

    it "同じタグは1つにする" do
      expect(TagList.parse("子猫, 子猫, #子猫")).to eq([ "子猫" ])
    end

    it "何も入っていなければ空の配列を返す" do
      expect(TagList.parse("")).to eq([])
      expect(TagList.parse(nil)).to eq([])
      expect(TagList.parse("   ")).to eq([])
      expect(TagList.parse(",,,")).to eq([])
    end
  end
end
