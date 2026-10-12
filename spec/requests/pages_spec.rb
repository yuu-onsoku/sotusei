require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /terms" do
    it "ログインしていなくても利用規約が表示される" do
      get terms_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /privacy" do
    it "ログインしていなくてもプライバシーポリシーが表示される" do
      get privacy_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /brand" do
    it "ログインしていなくてもブランドメッセージが表示される" do
      get brand_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /guideline" do
    it "ログインしていなくてもガイドラインが表示される" do
      get guideline_path
      expect(response).to have_http_status(:ok)
    end
  end

  # 登録画面には「利用規約とプライバシーポリシーに同意します」と書いてある。
  # リンクが切れていると、読まずに同意させることになるため、ここで固定する。
  describe "登録画面からの導線" do
    it "利用規約とプライバシーポリシーへのリンクがある" do
      get new_user_registration_path

      expect(response.body).to include(terms_path)
      expect(response.body).to include(privacy_path)
    end
  end

  # 以前、ブランドメッセージとガイドラインは href="#" のままで、押しても何も起きなかった。
  # 見た目があると動いていなくても気づけないので、繋がっていることをテストで固定する。
  describe "フッターからの導線" do
    let(:user) { create(:user) }

    it "ログイン後のページから、フッターの5つにすべて行ける" do
      sign_in user
      get questions_path

      [ brand_path, guideline_path, terms_path, privacy_path, new_contact_path ].each do |path|
        expect(response.body).to include(path)
      end
    end

    it "未ログインのトップからブランドメッセージに行ける" do
      get root_path

      expect(response.body).to include(brand_path)
    end
  end

  describe "質問の投稿画面からの導線" do
    it "ガイドラインへのリンクがある" do
      sign_in create(:user)
      get new_question_path

      expect(response.body).to include(guideline_path)
    end
  end
end
