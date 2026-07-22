class QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_own_question, only: %i[edit update destroy]

  # ねこの相談室（質問一覧）
  def index
    @questions = Question.search(params[:q]).includes(:user, :answers, :likes).order(created_at: :desc)
  end

  # 質問の詳細と、寄せられた回答の一覧
  def show
    @question = Question.includes(:user, :likes).find(params[:id])
    @answers = @question.answers.includes(:user, :likes, image_attachment: :blob).order(created_at: :asc)
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

  # 質問を編集する（フォーム）。テンプレートは投稿時と共通の post.html.erb。
  def edit
    render :post
  end

  # 質問の更新
  def update
    if @question.update(question_params)
      redirect_to question_path(@question), notice: "質問を更新しました。"
    else
      render :post, status: :unprocessable_entity
    end
  end

  # 質問の削除（回答・いいねも一緒に消える）
  def destroy
    @question.destroy
    redirect_to questions_path, notice: "質問を削除しました。"
  end

  private

  # 編集・削除できるのは自分の質問だけ
  def set_own_question
    @question = current_user.questions.find_by(id: params[:id])
    redirect_to questions_path, alert: "自分の質問だけが編集・削除できます。" if @question.nil?
  end

  def question_params
    params.require(:question).permit(:title, :content, :category, :image)
  end
end
