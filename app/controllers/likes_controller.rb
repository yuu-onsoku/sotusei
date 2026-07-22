class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  # いいねする（同じ対象には1回まで。二重送信されても増えない）
  def create
    current_user.likes.create(likeable: @likeable)
    respond_to_toggle
  end

  # いいねを取り消す
  def destroy
    current_user.likes.find_by(likeable: @likeable)&.destroy
    respond_to_toggle
  end

  private

  # 画面は押した時点で JS が更新済みなので、Turbo からの送信には何も返さない。
  # JS が無効な場合は元の画面へ戻す。
  def respond_to_toggle
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { redirect_back fallback_location: questions_path }
    end
  end

  # 質問・回答のどちらへのいいねかはネストされたパスで決まる
  def set_likeable
    @likeable =
      if params[:question_id]
        Question.find(params[:question_id])
      else
        Answer.find(params[:answer_id])
      end
  end
end
