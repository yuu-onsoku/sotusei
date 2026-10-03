require 'rails_helper'

RSpec.describe Post, type: :model do
  # 添付用のヘルパー。同じ記述が何度も出てくるのでまとめる
  def attach_image(post, filename: "test_image.png", content_type: "image/png")
    post.images.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/#{filename}")),
      filename: filename,
      content_type: content_type
    )
  end

  describe "写真" do
    it "1枚あれば有効" do
      expect(build(:post)).to be_valid
    end

    it "4枚まで有効" do
      post = build(:post)
      3.times { attach_image(post) }   # ファクトリの1枚 + 3枚 = 4枚

      expect(post.images.size).to eq(4)
      expect(post).to be_valid
    end

    it "5枚だと無効" do
      post = build(:post)
      4.times { attach_image(post) }   # 合計5枚

      expect(post).to be_invalid
      expect(post.errors[:images]).to include("は4枚までにしてください")
    end

    it "1枚も無いと無効" do
      post = build(:post)
      post.images.detach

      expect(post).to be_invalid
      expect(post.errors[:images]).to include("を1枚以上えらんでください")
    end

    it "画像でないファイルは無効" do
      post = build(:post)
      post.images.detach
      attach_image(post, filename: "not_image.txt", content_type: "text/plain")

      expect(post).to be_invalid
      expect(post.errors[:images]).to include("はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    it "5MBを超える写真があると無効" do
      post = build(:post)
      # 実際は70バイトだが、6MBということにする（大きなファイルを用意せずに検証するため）
      post.images.first.blob.byte_size = 6.megabytes

      expect(post).to be_invalid
      expect(post.errors[:images]).to include("は1枚5MB以下にしてください")
    end
  end

  describe "キャプション" do
    it "空でも有効" do
      expect(build(:post, content: nil)).to be_valid
    end

    it "1000文字までは有効" do
      expect(build(:post, content: "あ" * 1000)).to be_valid
    end

    it "1001文字だと無効" do
      expect(build(:post, content: "あ" * 1001)).to be_invalid
    end
  end

  describe "いいねとコメント" do
    it "いいねできる" do
      post = create(:post)
      create(:like, likeable: post)

      expect(post.reload.likes.size).to eq(1)
    end

    it "コメントできる" do
      post = create(:post)
      create(:comment, commentable: post)

      expect(post.reload.comments.size).to eq(1)
    end

    it "投稿を削除するといいねとコメントも消える" do
      post = create(:post)
      create(:like, likeable: post)
      create(:comment, commentable: post)

      expect { post.destroy }.to change(Like, :count).by(-1).and change(Comment, :count).by(-1)
    end
  end
end
