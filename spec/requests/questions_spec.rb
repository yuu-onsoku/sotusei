require 'rails_helper'

RSpec.describe "Questions", type: :request do
  describe "GET /questions" do
    context "ログインしているとき" do
      it "一覧ページが表示される" do
        user = create(:user)
        sign_in user               # ← ログインさせる（Deviseの機能）
        get questions_path         # ← ページを開く
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていないとき" do
      it "ログイン画面にリダイレクトされる" do
        get questions_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /questions/:id" do        # ① 名前を変える
    context "ログインしているとき" do
      it "詳細ページが表示される" do
        user = create(:user)
        question = create(:question)      # ② 見る対象を用意する（追加）
        sign_in user
        get question_path(question)       # ③ questions_path → question_path(question)
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていないとき" do
      it "ログイン画面にリダイレクトされる" do
        question = create(:question)
        get question_path(question)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
