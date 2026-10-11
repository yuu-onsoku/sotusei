require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "バリデーション" do
    it "名前がないと保存できない" do
      expect(Tag.new(name: "")).to be_invalid
    end

    it "同じ名前は2つ作れない" do
      create(:post, tag_names: "三毛猫")

      expect(Tag.new(name: "三毛猫")).to be_invalid
    end

    it "20文字を超えると保存できない" do
      expect(Tag.new(name: "あ" * 21)).to be_invalid
      expect(Tag.new(name: "あ" * 20)).to be_valid
    end
  end

  describe ".popular" do
    it "使われている数の多い順に並ぶ" do
      create(:post, tag_names: "子猫, 三毛猫")
      create(:post, tag_names: "子猫")

      expect(Tag.popular.map(&:name)).to eq([ "子猫", "三毛猫" ])
    end

    # 開くたびに並びが変わると、押したいタグの位置が動いて使いにくい
    it "同じ数のときは名前順に並ぶ" do
      create(:post, tag_names: "いぬ")
      create(:post, tag_names: "あめ")

      expect(Tag.popular.map(&:name)).to eq([ "あめ", "いぬ" ])
    end

    # 投稿を消すとタグだけ残る。それを帯に出すと押しても0件になる
    it "投稿が1件もないタグは出ない" do
      post = create(:post, tag_names: "だれも使っていない")
      post.destroy

      expect(Tag.popular).to be_empty
    end

    it "帯に出す数には上限がある" do
      names = (1..(Tag::POPULAR_LIMIT + 3)).map { |i| "タグ#{i}" }
      # 1投稿につき Post::MAX_TAGS 個までなので、分けて投稿する
      names.each_slice(Post::MAX_TAGS) { |group| create(:post, tag_names: group.join(",")) }

      # group を使った関係に .size を聞くと「グループごとの件数のハッシュ」が返るので、
      # 実際に読み込んで数える .length を使う
      expect(Tag.popular.length).to eq(Tag::POPULAR_LIMIT)
    end
  end
end
