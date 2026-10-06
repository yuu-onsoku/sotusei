require 'rails_helper'

RSpec.describe "Mypages", type: :request do
  it "ログインしていないと見られない" do
    get mypage_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "ログインしているとき" do
    let(:user) { create(:user) }
    before { sign_in user }

    it "表示される" do
      get mypage_path
      expect(response).to have_http_status(:ok)
    end

    it "タブを指定しないと質問が選ばれる" do
      get mypage_path
      expect(response.body).to include("まだ質問していません")
    end

    # 外から来た値をそのまま使わないことの確認
    it "知らないタブを指定しても落ちず、質問が選ばれる" do
      get mypage_path(tab: "destroy_everything")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ質問していません")
    end

    describe "自分のものだけが並ぶ" do
      it "質問" do
        mine = create(:question, user: user, title: "自分の質問です")
        others = create(:question, title: "他人の質問です")

        get mypage_path(tab: "questions")

        expect(response.body).to include(mine.title)
        expect(response.body).not_to include(others.title)
      end

      it "回答" do
        mine = create(:answer, user: user, content: "自分の回答です")
        others = create(:answer, content: "他人の回答です")

        get mypage_path(tab: "answers")

        expect(response.body).to include(mine.content)
        expect(response.body).not_to include(others.content)
      end

      it "にゃんスタの投稿" do
        mine = create(:post, user: user)
        others = create(:post)

        get mypage_path(tab: "posts")

        expect(response.body).to include(post_path(mine))
        expect(response.body).not_to include(post_path(others))
      end

      it "保存した投稿" do
        saved = create(:post)
        not_saved = create(:post)
        create(:bookmark, bookmarkable: saved, user: user)

        get mypage_path(tab: "bookmarks")

        expect(response.body).to include(post_path(saved))
        expect(response.body).not_to include(post_path(not_saved))
      end
    end

    it "選んでいるタブの中身だけが表示される" do
      create(:question, user: user, title: "自分の質問です")
      own_post = create(:post, user: user)

      get mypage_path(tab: "questions")

      expect(response.body).to include("自分の質問です")
      expect(response.body).not_to include(post_path(own_post))
    end
  end
end
