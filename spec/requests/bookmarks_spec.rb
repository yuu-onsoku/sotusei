require 'rails_helper'

RSpec.describe "Bookmarks", type: :request do
  describe "ログインしていないとき" do
    it "保存できない" do
      nyansta_post = create(:post)

      post post_bookmark_path(nyansta_post)

      expect(Bookmark.count).to eq(0)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "保存した投稿の一覧を見られない" do
      get bookmarks_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログインしているとき" do
    describe "POST /posts/:post_id/bookmark" do
      it "投稿を保存できる" do
        user = create(:user)
        nyansta_post = create(:post)
        sign_in user

        post post_bookmark_path(nyansta_post)

        expect(nyansta_post.bookmarks.count).to eq(1)
      end

      # 同じ送信が二重に届いても増えないこと（いいねと同じ考え方）
      it "同じ投稿を2回保存しても1件のまま" do
        user = create(:user)
        nyansta_post = create(:post)
        sign_in user

        post post_bookmark_path(nyansta_post)
        post post_bookmark_path(nyansta_post)

        expect(nyansta_post.bookmarks.count).to eq(1)
      end
    end

    describe "DELETE /posts/:post_id/bookmark" do
      it "保存を外せる" do
        user = create(:user)
        nyansta_post = create(:post)
        create(:bookmark, bookmarkable: nyansta_post, user: user)
        sign_in user

        delete post_bookmark_path(nyansta_post)

        expect(nyansta_post.bookmarks.count).to eq(0)
      end

      # 保存していない状態で外しても壊れないこと
      it "保存していない投稿の保存を外しても壊れない" do
        user = create(:user)
        nyansta_post = create(:post)
        sign_in user

        delete post_bookmark_path(nyansta_post)

        expect(response).to have_http_status(:found)
        expect(nyansta_post.bookmarks.count).to eq(0)
      end
    end

    describe "GET /bookmarks" do
      it "一覧が表示される" do
        sign_in create(:user)

        get bookmarks_path

        expect(response).to have_http_status(:ok)
      end

      it "自分が保存した投稿だけが並ぶ" do
        user = create(:user)
        mine = create(:post, content: "自分が保存した投稿")
        others = create(:post, content: "他人が保存した投稿")

        create(:bookmark, bookmarkable: mine, user: user)
        create(:bookmark, bookmarkable: others)   # 別のユーザーの保存

        sign_in user
        get bookmarks_path

        expect(response.body).to include(post_path(mine))
        expect(response.body).not_to include(post_path(others))
      end
    end

    describe "保存ボタンの再描画" do
      it "turbo_stream でボタンが描き直される" do
        user = create(:user)
        nyansta_post = create(:post)
        sign_in user

        post post_bookmark_path(nyansta_post), as: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("bookmark_form")
      end
    end
  end
end
