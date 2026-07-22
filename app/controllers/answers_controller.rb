class AnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question
  before_action :set_own_answer, only: %i[edit update]

  # 回答を投稿する（フォーム）
  def new
    @answer = @question.answers.build
  end

  # 回答の保存
  def create
    @answer = @question.answers.build(answer_params)
    @answer.user = current_user
    if @answer.save
      redirect_to question_path(@question), notice: "回答を投稿しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 回答を編集する（フォーム）。テンプレートは投稿時と共通の new.html.erb。
  def edit
    render :new
  end

  # 回答の更新
  def update
    if @answer.update(answer_params)
      redirect_to question_path(@question), notice: "回答を更新しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
  end

  # 編集できるのは自分の回答だけ
  def set_own_answer
    @answer = @question.answers.where(user: current_user).find_by(id: params[:id])
    redirect_to question_path(@question), alert: "編集できるのは自分の回答だけです。" if @answer.nil?
  end

  def answer_params
    params.require(:answer).permit(:content, :image)
  end
end
