class QuestionsController < ApplicationController
  before_action :authenticate_user!

  # ねこの相談室（質問一覧）
  def index
    @questions = Question.search(params[:q]).includes(:user, :answers, :likes).order(created_at: :desc)
  end

  # 質問の詳細と、寄せられた回答の一覧
  def show
    @question = Question.includes(:user, :likes).find(params[:id])
    @answers = @question.answers.includes(:user, image_attachment: :blob).order(created_at: :asc)
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
    params.require(:question).permit(:title, :content, :category, :image)
  end
end
