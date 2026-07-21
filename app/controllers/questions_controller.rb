class QuestionsController < ApplicationController
  before_action :authenticate_user!

  # ねこの相談室（質問一覧）
  def index
    @questions = Question.includes(:user).order(created_at: :desc)
  end

  # 質問を投稿する（フォーム）。テンプレートは post.html.erb。
  def new
    @question = Question.new
    render :post
  end

  # 質問の保存
  def create
    @question = current_user.questions.build(question_params)
    if @question.save
      redirect_to questions_path, notice: "質問を投稿しました。"
    else
      render :post, status: :unprocessable_entity
    end
  end

  private

  def question_params
    params.require(:question).permit(:title, :content, :category)
  end
end
