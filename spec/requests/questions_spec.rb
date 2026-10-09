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

  describe "GET /questions/:id" do
    context "ログインしているとき" do
      it "詳細ページが表示される" do
        user = create(:user)
        question = create(:question)
        sign_in user
        get question_path(question)
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

  describe "POST /questions" do
    context "ログインしていて、入力が正しいとき" do
      it "質問が作成される" do
        user = create(:user)
        sign_in user

        post questions_path, params: {
          question: {
            title: "猫のごはんについて",
            content: "食欲がないのですが、どうすればいいでしょうか。",
            category: "食事"
          }
        }

        expect(Question.count).to eq(1)
        expect(response).to redirect_to(questions_path)
      end
    end

    context "入力が正しくないとき" do
      it "質問が作成されない" do
        user = create(:user)
        sign_in user

        post questions_path, params: {
          question: {
            title: "",
            content: "食欲がないのですが",
            category: "食事"
          }
        }

        expect(Question.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /questions/:id" do
    context "他人の質問を消去しようとしたとき" do
      it "消去されず、一覧にリダイレクトされる" do
        owner = create(:user)
        question = create(:question, user: owner)

        other = create(:user)
        sign_in other

        delete question_path(question)

        expect(Question.count).to eq(1)
        expect(response).to redirect_to(questions_path)
      end
    end
  end

  describe "GET /questions/:id/edit" do
    context "他人の質問のとき" do
      it "編集画面を開けず、一覧にリダイレクトされる" do
        owner = create(:user)
        question = create(:question, user: owner)
        other = create(:user)
        sign_in other
        get edit_question_path(question)
        expect(response).to redirect_to(questions_path)
      end
    end

    context "自分の質問のとき" do
      it "編集画面を開ける" do
        user = create(:user)
        question = create(:question, user: user)
        sign_in user

        get edit_question_path(question)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /questions/:id" do
    context "他人の質問のとき" do
      it "更新できない" do
        owner = create(:user)
        question = create(:question, user: owner, title: "元のタイトル")

        other = create(:user)
        sign_in other

        patch question_path(question), params: {
          question: { title: "書き換えられたタイトル" }
        }

        expect(question.reload.title).to eq("元のタイトル")
        expect(response).to redirect_to(questions_path)
      end
    end

    context "自分の質問のとき" do
      it "更新できる" do
        user = create(:user)
        question = create(:question, user: user, title: "元のタイトル")
        sign_in user

        patch question_path(question), params: {
          question: { title: "新しいタイトル" }
        }

        expect(question.reload.title).to eq("新しいタイトル")
        expect(response).to redirect_to(question_path(question))
      end
    end
  end
  describe "ページ分け" do
    before { sign_in create(:user) }

    it "1ページ目には12件まで出る" do
      create_list(:question, 13)

      get questions_path

      expect(response.body.scan(/questions\/\d+"/).uniq.size).to be <= 12
    end

    it "2ページ目には続きが出る" do
      create_list(:question, 13)
      newest = Question.order(created_at: :desc).first
      oldest = Question.order(created_at: :desc).last

      get questions_path(page: 2)

      expect(response.body).to include(oldest.title)
      expect(response.body).not_to include(newest.title)
    end

    # 範囲外を指定されても画面が壊れないこと
    it "存在しないページでも落ちない" do
      create_list(:question, 3)

      get questions_path(page: 999)

      expect(response).to have_http_status(:ok)
    end

    # 検索したままページを移動できること
    it "検索の言葉がページ送りに引き継がれる" do
      create_list(:question, 13, title: "ねこのごはんについて")

      get questions_path(q: "ごはん")

      expect(response.body).to include("q=")
    end
  end
end
