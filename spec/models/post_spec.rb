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

    it "20MBを超える写真があると無効" do
      post = build(:post)
      # 実際は70バイトだが、21MBということにする（大きなファイルを用意せずに検証するため）
      post.images.first.blob.byte_size = 21.megabytes

      expect(post).to be_invalid
      expect(post.errors[:images]).to include("は1枚20MB以下にしてください")
    end

    # 5MBを超える写真も受け入れる。投稿される前に ImageResizer が縮めるため。
    it "6MBの写真でも有効" do
      post = build(:post)
      post.images.first.blob.byte_size = 6.megabytes

      expect(post).to be_valid
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

  describe "タグ" do
    it "カンマ区切りの文字列からタグを作って付ける" do
      post = create(:post, tag_names: "三毛猫, 子猫")

      expect(post.tags.map(&:name)).to contain_exactly("三毛猫", "子猫")
    end

    it "タグなしでも投稿できる" do
      expect(build(:post, tag_names: "")).to be_valid
      expect(create(:post).tags).to be_empty
    end

    it "すでにあるタグ名は作り直さず使い回す" do
      create(:post, tag_names: "子猫")

      expect { create(:post, tag_names: "子猫, 寝顔") }.to change(Tag, :count).by(1)
    end

    it "6個以上は保存できない" do
      post = build(:post, tag_names: "a,b,c,d,e,f")

      expect(post).to be_invalid
      expect(post.errors.full_messages).to include("タグは5個までにしてください")
    end

    it "1つが20文字を超えると保存できない" do
      post = build(:post, tag_names: "あ" * 21)

      expect(post).to be_invalid
      expect(post.errors.full_messages).to include("タグは1つ20文字までにしてください")
    end

    # 保存に失敗した投稿のためにタグだけ増やさない
    it "保存に失敗したときはタグも作られない" do
      post = build(:post, content: "あ" * 1001, tag_names: "まだ無いタグ")

      expect { post.save }.not_to change(Tag, :count)
    end

    it "編集でタグを入れ替えられる" do
      post = create(:post, tag_names: "三毛猫, 子猫")

      post.update(tag_names: "寝顔")

      expect(post.reload.tags.map(&:name)).to eq([ "寝顔" ])
    end

    it "編集でタグを空にできる" do
      post = create(:post, tag_names: "三毛猫")

      post.update(tag_names: "")

      expect(post.reload.tags).to be_empty
    end

    # タグに触らない更新で、付いているタグが消えてしまわないこと
    it "タグを送らない更新ではタグがそのまま残る" do
      post = create(:post, tag_names: "三毛猫")

      post.update(content: "ひとことだけ直す")

      expect(post.reload.tags.map(&:name)).to eq([ "三毛猫" ])
    end

    # Tag は他の投稿が使っているかもしれないので消さない
    it "投稿を削除しても Tag は残り、中間テーブルだけ消える" do
      post = create(:post, tag_names: "三毛猫")

      expect { post.destroy }.to change(PostTag, :count).by(-1).and change(Tag, :count).by(0)
    end
  end
end
