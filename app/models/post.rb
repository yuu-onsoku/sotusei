class Post < ApplicationRecord
  # いいね（肉球ボタン）とコメントは共通部品に任せる
  include Likeable
  include Commentable
  include Bookmarkable

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  # 投稿前に ImageResizer が縮めるので、受け入れる元ファイルの上限として持つ
  IMAGE_MAX_SIZE = 20.megabytes
  MAX_IMAGES = 4
  MAX_TAGS = 5

  belongs_to :user

  # 写真は1枚以上4枚まで（写真共有なので写真なしの投稿は作れない）
  has_many_attached :images

  # タグ。投稿を消しても Tag は残す（他の投稿が使っているかもしれない）ので、
  # dependent: :destroy を付けるのは中間テーブルの側だけ
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :content, length: { maximum: 1000 }
  validate :acceptable_images
  validate :acceptable_tags

  # Tag の行を作るのは、投稿の保存が通ってから。
  # 保存に失敗した投稿のためにタグだけ増やさないため（ProfileForm で purge を
  # 検証のあとに移したのと同じ考え方）
  after_save :sync_tags, if: -> { @tag_names }

  # 画面から届くのはカンマ区切りの1行なので、配列に直して預かる
  def tag_names=(value)
    @tag_names = TagList.parse(value)
  end

  # フォームに出す文字列。まだ入力されていなければ、いま付いているタグを出す
  def tag_names
    @tag_names || tags.map(&:name)
  end

  private

  def acceptable_images
    if images.empty?
      errors.add(:images, "を1枚以上えらんでください")
      return
    end

    if images.size > MAX_IMAGES
      errors.add(:images, "は#{MAX_IMAGES}枚までにしてください")
    end

    images.each do |image|
      unless image.content_type.in?(IMAGE_CONTENT_TYPES)
        errors.add(:images, "はPNG / JPEG / GIF / WEBP 形式で添付してください")
      end

      if image.byte_size > IMAGE_MAX_SIZE
        errors.add(:images, "は1枚20MB以下にしてください")
      end
    end
  end

  def acceptable_tags
    # タグを一度も触っていない更新（キャプションだけ直した、など）では検証しない
    return if @tag_names.nil?

    if @tag_names.size > MAX_TAGS
      errors.add(:tags, "は#{MAX_TAGS}個までにしてください")
    end

    if @tag_names.any? { |name| name.length > TagList::MAX_LENGTH }
      errors.add(:tags, "は1つ#{TagList::MAX_LENGTH}文字までにしてください")
    end
  end

  # 入力されたタグ名で、付いているタグを入れ替える。
  # 代入するだけで post_tags の作成・削除は Rails がやってくれる
  def sync_tags
    self.tags = @tag_names.map { |name| find_or_create_tag(name) }
  end

  # tags.name には重複を禁止するインデックスを張ってある。
  # 2人が同時に同じタグを付けると find_or_create_by でも衝突しうるので、
  # そのときは「相手が作ったもの」を拾い直す
  def find_or_create_tag(name)
    Tag.find_or_create_by!(name: name)
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name: name)
  end
end
