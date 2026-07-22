class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  # いいねする。すでにいいね済みなら何もしない（二重送信されても増えない）。
  def create
    current_user.likes.create(likeable: @likeable)
    render_button
  end

  # いいねを取り消す。いいねが無ければ何もしない（二重送信されても壊れない）。
  def destroy
    current_user.likes.find_by(likeable: @likeable)&.destroy
    render_button
  end

  private

  # ボタンだけを描き直して、画面をサーバーの状態に合わせる。
  # JS が無効な場合は元の画面へ戻す。
  def render_button
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@likeable, :like_form),
          partial: "likes/form",
          locals: { likeable: @likeable.reload }
        )
      end
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
