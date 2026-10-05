require 'rails_helper'

RSpec.describe Contact, type: :model do
  it "必要な項目がそろっていれば有効" do
    expect(build(:contact)).to be_valid
  end

  describe "お名前" do
    it "空でも有効（任意のため）" do
      expect(build(:contact, name: "")).to be_valid
    end

    it "51文字だと無効" do
      expect(build(:contact, name: "あ" * 51)).to be_invalid
    end
  end

  describe "メールアドレス" do
    it "空だと無効（返信できなくなるため）" do
      expect(build(:contact, email: "")).to be_invalid
    end

    it "形式が正しくないと無効" do
      expect(build(:contact, email: "neko")).to be_invalid
      expect(build(:contact, email: "neko@")).to be_invalid
      expect(build(:contact, email: "neko@example")).to be_invalid
    end

    it "正しい形式なら有効" do
      expect(build(:contact, email: "neko@example.com")).to be_valid
    end
  end

  describe "お問い合わせ内容" do
    it "空だと無効" do
      expect(build(:contact, content: "")).to be_invalid
    end

    it "2000文字までは有効" do
      expect(build(:contact, content: "あ" * 2000)).to be_valid
    end

    it "2001文字だと無効" do
      expect(build(:contact, content: "あ" * 2001)).to be_invalid
    end
  end
end
