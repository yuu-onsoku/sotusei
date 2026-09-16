require 'rails_helper'

RSpec.describe "Answers", type: :request do
  describe "POST /questions/:question_id/answers" do
    context "ログインしていて、入力が正しいとき" do
      it "回答が作成される" do
        user = create(:user)
        question = create(:question)
        sign_in user

        post question_answers_path(question), params: {
          answer: { content: "うちの子も同じでした。病院で相談するのがおすすめです。" }
        }

        expect(Answer.count).to eq(1)
        expect(response).to redirect_to(question_path(question))
      end
    end

    context "入力が正しくないとき" do
      it "回答が作成されない" do
        user = create(:user)
        question = create(:question)
        sign_in user

        post question_answers_path(question), params: {
          answer: { content: "" }
        }

        expect(Answer.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /questions/:question_id/answers/:id" do
    context "他人の回答のとき" do
      it "削除されず、質問の詳細にリダイレクトされる" do
        question = create(:question)
        owner = create(:user)
        answer = create(:answer, question: question, user: owner)

        other = create(:user)
        sign_in other

        delete question_answer_path(question, answer)

        expect(Answer.count).to eq(1)
        expect(response).to redirect_to(question_path(question))
      end
    end
  end

  describe "GET /questions/:question_id/answers/:id/edit" do
    context "他人の回答のとき" do
      it "編集画面を開けず、質問の詳細にリダイレクトされる" do
        question = create(:question)
        owner = create(:user)
        answer = create(:answer, question: question, user: owner)

        other = create(:user)
        sign_in other

        get edit_question_answer_path(question, answer)

        expect(response).to redirect_to(question_path(question))
      end
    end

    context "自分の回答のとき" do
      it "編集画面を開ける" do
        question = create(:question)
        user = create(:user)
        answer = create(:answer, question: question, user: user)
        sign_in user

        get edit_question_answer_path(question, answer)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /questions/:question_id/answers/:id" do
    context "他人の回答のとき" do
      it "更新できない" do
        question = create(:question)
        owner = create(:user)
        answer = create(:answer, question: question, user: owner, content: "元の回答")

        other = create(:user)
        sign_in other

        patch question_answer_path(question, answer), params: {
          answer: { content: "書き換えられた回答" }
        }

        expect(answer.reload.content).to eq("元の回答")
        expect(response).to redirect_to(question_path(question))
      end
    end

    context "自分の回答のとき" do
      it "更新できる" do
        question = create(:question)
        user = create(:user)
        answer = create(:answer, question: question, user: user, content: "元の回答")
        sign_in user

        patch question_answer_path(question, answer), params: {
          answer: { content: "新しい回答" }
        }

        expect(answer.reload.content).to eq("新しい回答")
        expect(response).to redirect_to(question_path(question))
      end
    end
  end

    context "ログインしていないとき" do
      it "回答を投稿できない" do
        question = create(:question)

        post question_answers_path(question), params: {
          answer: { content: "ログインせずに投稿" }
        }

        expect(Answer.count).to eq(0)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
end
