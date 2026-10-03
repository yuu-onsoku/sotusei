class Post < ApplicationRecord
  # いいね（肉球ボタン）とコメントは共通部品に任せる
  include Likeable
  include Commentable
  include Bookmarkable

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes
  MAX_IMAGES = 4

  belongs_to :user

  # 写真は1枚以上4枚まで（写真共有なので写真なしの投稿は作れない）
  has_many_attached :images

  validates :content, length: { maximum: 1000 }
  validate :acceptable_images

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
        errors.add(:images, "は1枚5MB以下にしてください")
      end
    end
  end
end
