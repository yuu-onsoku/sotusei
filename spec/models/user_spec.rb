require 'rails_helper'

RSpec.describe User, type: :model do
    it "ファクトリのデフォルト値で有効になる" do
      expect(build(:user)).to be_valid
    end

  describe "username" do
    it "空だと無効になる" do
      user = build(:user, username: "")
      expect(user).to be_invalid
    end

    it "30文字ちょうどなら有効になる" do
      user = build(:user, username: "あ" * 30)
      expect(user).to be_valid
    end

    it "31文字だと無効になる" do
     user = build(:user, username: "あ" * 31)
     expect(user).to be_invalid
    end

    it "usernameが他の人とかぶっていると無効になる" do
      create(:user, username: "tama")              # ① 先に名簿に書く（create！）
      duplicate = build(:user, username: "tama")   # ② 同じ名前で作ろうとする
     expect(duplicate).to be_invalid              # ③ ダメなはず
    end
  end

  describe "name" do
    it "空でも有効になる" do
      user = build(:user, name: "")
      expect(user).to be_valid
    end

    it "50文字ちょうどなら有効" do
      user = build(:user, name: "あ" * 50)
      expect(user).to be_valid
    end

    it "51文字だと無効になる" do
      user = build(:user, name: "あ" * 51)
      expect(user).to be_invalid
    end
  end

  describe "email" do
    it "空だと無効になる" do
      user = build(:user, email: "")
      expect(user).to be_invalid
    end

    it "@がない形式だと無効になる" do
      user = build(:user, email: "abc")
      expect(user).to be_invalid
    end

    it "他の人とかぶっていると無効になる" do
      create(:user, email: "nekoneko@gmail.com")
      duplicate = build(:user, email: "nekoneko@gmail.com")
      expect(duplicate).to be_invalid
    end
  end

  describe "password" do
    it "空だと無効になる" do
      user = build(:user, password: "")
      expect(user).to be_invalid
    end

    it "7文字だと無効になる" do
      user = build(:user, password: "あ" * 7)
      expect(user).to be_invalid
    end

    it "8文字ちょうどなら有効になる" do
      user = build(:user, password: "あ" * 8)
      expect(user).to be_valid
    end
  end

  describe "アイコン" do
    def attach_avatar(user, filename: "test_image.png", content_type: "image/png")
      user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/#{filename}")),
        filename: filename,
        content_type: content_type
      )
    end

    it "設定しなくても有効（任意のため）" do
      expect(build(:user)).to be_valid
    end

    it "画像を設定できる" do
      user = build(:user)
      attach_avatar(user)

      expect(user).to be_valid
    end

    it "画像でないファイルは無効" do
      user = build(:user)
      attach_avatar(user, filename: "not_image.txt", content_type: "text/plain")

      expect(user).to be_invalid
      expect(user.errors[:avatar]).to include("はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    it "5MBを超えると無効" do
      user = build(:user)
      attach_avatar(user)
      # 実際は70バイトだが、6MBということにする
      user.avatar.blob.byte_size = 6.megabytes

      expect(user).to be_invalid
      expect(user.errors[:avatar]).to include("は5MB以下にしてください")
    end
  end
end
