class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable
  before_action :set_own_comment, only: %i[edit update destroy]

  # コメントの保存
  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save
      redirect_to question_path(question_of(@commentable)), notice: "コメントを投稿しました。"
    else
      redirect_to question_path(question_of(@commentable)), alert: "コメントを投稿できませんでした。"
    end
  end

  # コメントを編集する（フォーム）
  def edit
  end

  # コメントの更新
  def update
    if @comment.update(comment_params)
      redirect_to question_path(question_of(@commentable)), notice: "コメントを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # コメントの削除
  def destroy
    @comment.destroy
    redirect_to question_path(question_of(@commentable)), notice: "コメントを削除しました。"
  end

  private

  # 質問・回答のどちらへのコメントかはネストされたパスで決まる
  def set_commentable
    @commentable =
      if params[:question_id]
        Question.find(params[:question_id])
      else
        Answer.find(params[:answer_id])
      end
  end

  # 編集・削除できるのは自分のコメントだけ
  def set_own_comment
    @comment = @commentable.comments.where(user: current_user).find_by(id: params[:id])
    redirect_to question_path(question_of(@commentable)), alert: "自分のコメントだけが編集・削除できます。" if @comment.nil?
  end

  # 回答へのコメントでも、戻る先は質問の詳細画面
  def question_of(commentable)
    commentable.is_a?(Question) ? commentable : commentable.question
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
