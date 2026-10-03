require 'rails_helper'

RSpec.describe Bookmark, type: :model do
  it "投稿をブックマークできる" do
    expect(build(:bookmark)).to be_valid
  end

  it "同じ人が同じ投稿を2回ブックマークできない" do
    nyansta_post = create(:post)
    user = create(:user)
    create(:bookmark, bookmarkable: nyansta_post, user: user)

    expect(build(:bookmark, bookmarkable: nyansta_post, user: user)).to be_invalid
  end

  it "別の人なら同じ投稿をブックマークできる" do
    nyansta_post = create(:post)
    create(:bookmark, bookmarkable: nyansta_post)

    expect(build(:bookmark, bookmarkable: nyansta_post)).to be_valid
  end

  describe "#bookmarked_by?" do
    it "保存していればtrue" do
      nyansta_post = create(:post)
      user = create(:user)
      create(:bookmark, bookmarkable: nyansta_post, user: user)

      expect(nyansta_post.reload.bookmarked_by?(user)).to be true
    end

    it "保存していなければfalse" do
      expect(create(:post).bookmarked_by?(create(:user))).to be false
    end

    it "未ログイン（nil）ならfalse" do
      expect(create(:post).bookmarked_by?(nil)).to be false
    end
  end

  it "投稿を削除するとブックマークも消える" do
    nyansta_post = create(:post)
    create(:bookmark, bookmarkable: nyansta_post)

    expect { nyansta_post.destroy }.to change(Bookmark, :count).by(-1)
  end
end
