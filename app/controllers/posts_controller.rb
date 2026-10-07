class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_own_post, only: %i[edit update destroy]

  # にゃんスタ（投稿の一覧）
  def index
    @posts = Post.includes(:user, :likes, images_attachments: :blob).order(created_at: :desc)
  end

  # 投稿の詳細
  def show
    @post = Post.includes(:likes, { user: { avatar_attachment: :blob } }, { comments: :user }, images_attachments: :blob).find(params[:id])
  end

  # 投稿する（フォーム）
  def new
    @post = Post.new
  end

  # 投稿の保存
  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to posts_path, notice: "写真を投稿しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 投稿を編集する（フォーム）
  def edit
  end

  # 投稿の更新
  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "投稿を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 投稿の削除（いいね・コメントも一緒に消える）
  def destroy
    @post.destroy
    redirect_to posts_path, notice: "投稿を削除しました。"
  end

  private

  # 編集・削除できるのは自分の投稿だけ
  def set_own_post
    @post = current_user.posts.find_by(id: params[:id])
    redirect_to posts_path, alert: "自分の投稿だけが編集・削除できます。" if @post.nil?
  end

  # ファイルを1つも選ばずに送ると images が [""] の形で届く。
  # そのまま渡すと、編集時に今ある写真が消えてしまうため、空を取り除く。
  def post_params
    permitted = params.require(:post).permit(:content, images: [])
    permitted[:images] = permitted[:images].reject(&:blank?) if permitted[:images]
    permitted.delete(:images) if permitted[:images].blank?
    permitted
  end
end
