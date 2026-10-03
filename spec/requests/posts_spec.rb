require 'rails_helper'

RSpec.describe "Posts", type: :request do
  # 写真を添えてフォーム送信するときの材料
  def image_file
    fixture_file_upload("spec/fixtures/files/test_image.png", "image/png")
  end

  describe "ログインしていないとき" do
    it "一覧を見られない" do
      get posts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "投稿できない" do
      expect {
        post posts_path, params: { post: { content: "うちの子", images: [ image_file ] } }
      }.not_to change(Post, :count)
    end
  end

  describe "ログインしているとき" do
    before { sign_in create(:user) }

    describe "GET /posts" do
      it "一覧が表示される" do
        create(:post)
        get posts_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /posts/:id" do
      it "詳細が表示される" do
        get post_path(create(:post))
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /posts" do
      it "写真1枚で投稿できる" do
        expect {
          post posts_path, params: { post: { content: "今日もよく寝ています", images: [ image_file ] } }
        }.to change(Post, :count).by(1)

        expect(response).to redirect_to(posts_path)
      end

      it "写真4枚まで投稿できる" do
        expect {
          post posts_path, params: { post: { images: [ image_file, image_file, image_file, image_file ] } }
        }.to change(Post, :count).by(1)
      end

      it "写真5枚だと投稿できない" do
        expect {
          post posts_path, params: { post: { images: Array.new(5) { image_file } } }
        }.not_to change(Post, :count)
      end

      it "写真が無いと投稿できない" do
        expect {
          post posts_path, params: { post: { content: "写真なし" } }
        }.not_to change(Post, :count)
      end
    end

    describe "自分の投稿" do
      it "更新できる" do
        user = create(:user)
        sign_in user
        own_post = create(:post, user: user)

        patch post_path(own_post), params: { post: { content: "書き直しました" } }

        expect(own_post.reload.content).to eq("書き直しました")
      end

      # 写真を選ばずに更新すると images が [""] で届く。
      # そのまま渡すと写真が全部消えるため、コントローラで空を取り除いている。
      it "写真をえらばずに更新しても、写真が消えない" do
        user = create(:user)
        sign_in user
        own_post = create(:post, user: user)

        patch post_path(own_post), params: { post: { content: "ひとことだけ変える", images: [ "" ] } }

        expect(own_post.reload.images.size).to eq(1)
      end

      it "削除できる" do
        user = create(:user)
        sign_in user
        own_post = create(:post, user: user)

        expect { delete post_path(own_post) }.to change(Post, :count).by(-1)
      end
    end

    describe "他人の投稿" do
      it "編集画面を開けない" do
        get edit_post_path(create(:post))
        expect(response).to redirect_to(posts_path)
      end

      it "更新できない" do
        other = create(:post, content: "もとの文章")

        patch post_path(other), params: { post: { content: "書き換えた" } }

        expect(other.reload.content).to eq("もとの文章")
      end

      it "削除できない" do
        other = create(:post)
        expect { delete post_path(other) }.not_to change(Post, :count)
      end
    end
  end
end
