class BookmarksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bookmarkable, only: %i[create destroy]

  # 保存した投稿の一覧
  def index
    @bookmarks = current_user.bookmarks
                             .includes(bookmarkable: [ :user, :likes, { images_attachments: :blob } ])
                             .order(created_at: :desc)
  end

  # 保存する。すでに保存済みなら何もしない（二重送信されても増えない）。
  def create
    current_user.bookmarks.create(bookmarkable: @bookmarkable)
    render_button
  end

  # 保存を外す。保存していなければ何もしない（二重送信されても壊れない）。
  def destroy
    current_user.bookmarks.find_by(bookmarkable: @bookmarkable)&.destroy
    render_button
  end

  private

  # ボタンだけを描き直して、画面をサーバーの状態に合わせる。
  # JS が無効な場合は元の画面へ戻す。
  def render_button
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@bookmarkable, :bookmark_form),
          partial: "bookmarks/form",
          locals: { bookmarkable: @bookmarkable.reload }
        )
      end
      format.html { redirect_back fallback_location: posts_path }
    end
  end

  # 今はにゃんスタの投稿のみ。質問などに広げるときはここに足す。
  def set_bookmarkable
    @bookmarkable = Post.find(params[:post_id])
  end
end
