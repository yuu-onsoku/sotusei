require 'rails_helper'

RSpec.describe "Likes", type: :request do
  describe "POST /questions/:question_id/like" do
    it "同じ質問に2回いいねしても1件のまま" do
      user = create(:user)
      question = create(:question)
      sign_in user
      post question_like_path(question)    # 1回目
      post question_like_path(question)    # 2回目（二重送信を再現）
      expect(Like.count).to eq(1)
    end
  end

  describe "DELETE /questions/:question_id/like" do
    it "いいねしていない状態で取り消しても壊れない" do
      user = create(:user)
      question = create(:question)
      sign_in user
      delete question_like_path(question)
      expect(Like.count).to eq(0)
      expect(response).to have_http_status(:ok).or have_http_status(:found)
    end
  end

  describe "POST /answers/:answer_id/like" do
    it "同じ回答に2回いいねしても1件のまま" do
      user = create(:user)
      answer = create(:answer)
      sign_in user
      post answer_like_path(answer)
      post answer_like_path(answer)
      expect(Like.count).to eq(1)
    end
  end

  context "ログインしていないとき" do
    it "いいねできない" do
      question = create(:question)
      post question_like_path(question)
      expect(Like.count).to eq(0)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "いいね後のボタン再描画" do
    it "turbo_stream でボタンが描き直される" do
      user = create(:user)
      question = create(:question)
      sign_in user

      post question_like_path(question), as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("like_form")
    end
  end
end
