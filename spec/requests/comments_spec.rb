require 'rails_helper'

RSpec.describe "Comments", type: :request do
  describe "ログインしていないとき" do
    it "コメントできない" do
      question = create(:question)

      expect {
        post question_comments_path(question), params: { comment: { content: "こんにちは" } }
      }.not_to change(Comment, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログインしているとき" do
    before { sign_in create(:user) }

    describe "POST /questions/:question_id/comments" do
      it "質問にコメントできる" do
        question = create(:question)

        expect {
          post question_comments_path(question), params: { comment: { content: "参考になりました" } }
        }.to change(Comment, :count).by(1)

        expect(response).to redirect_to(question_path(question))
      end

      it "空のコメントは保存されない" do
        question = create(:question)

        expect {
          post question_comments_path(question), params: { comment: { content: "" } }
        }.not_to change(Comment, :count)
      end
    end

    describe "POST /answers/:answer_id/comments" do
      it "回答にコメントでき、質問の詳細に戻る" do
        answer = create(:answer)

        expect {
          post answer_comments_path(answer), params: { comment: { content: "ありがとうございます" } }
        }.to change(Comment, :count).by(1)

        expect(response).to redirect_to(question_path(answer.question))
      end
    end

    describe "自分のコメント" do
      it "更新できる" do
        user = create(:user)
        sign_in user
        question = create(:question)
        comment = create(:comment, commentable: question, user: user)

        patch question_comment_path(question, comment), params: { comment: { content: "書き直しました" } }

        expect(comment.reload.content).to eq("書き直しました")
      end

      it "削除できる" do
        user = create(:user)
        sign_in user
        question = create(:question)
        comment = create(:comment, commentable: question, user: user)

        expect {
          delete question_comment_path(question, comment)
        }.to change(Comment, :count).by(-1)
      end
    end

    describe "POST /posts/:post_id/comments" do
      it "にゃんスタの投稿にコメントでき、投稿の詳細に戻る" do
        nyansta_post = create(:post)

        expect {
          post post_comments_path(nyansta_post), params: { comment: { content: "かわいいです" } }
        }.to change(Comment, :count).by(1)

        expect(response).to redirect_to(post_path(nyansta_post))
      end

      # 戻り先を back_path にまとめているので、投稿でも正しい場所へ戻る必要がある
      it "他人のコメントは編集画面を開けず、投稿の詳細に戻される" do
        nyansta_post = create(:post)
        comment = create(:comment, commentable: nyansta_post)

        get edit_post_comment_path(nyansta_post, comment)

        expect(response).to redirect_to(post_path(nyansta_post))
      end
    end

    # 講師から指摘のあった「他人の投稿を編集・削除できない」をここでも守る
    describe "他人のコメント" do
      it "編集画面を開けない" do
        question = create(:question)
        comment = create(:comment, commentable: question)   # 別のユーザーのコメント

        get edit_question_comment_path(question, comment)

        expect(response).to redirect_to(question_path(question))
      end

      it "更新できない" do
        question = create(:question)
        comment = create(:comment, commentable: question, content: "もとの文章")

        patch question_comment_path(question, comment), params: { comment: { content: "書き換えた" } }

        expect(comment.reload.content).to eq("もとの文章")
      end

      it "削除できない" do
        question = create(:question)
        comment = create(:comment, commentable: question)

        expect {
          delete question_comment_path(question, comment)
        }.not_to change(Comment, :count)
      end
    end
  end
end
