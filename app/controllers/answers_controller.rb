class AnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question

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

  private

  def set_question
    @question = Question.find(params[:question_id])
  end

  def answer_params
    params.require(:answer).permit(:content, :image)
  end
end
