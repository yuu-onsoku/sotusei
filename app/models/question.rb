class Question < ApplicationRecord
  belongs_to :user

  # 添付画像（任意）
  has_one_attached :image

  # 投稿フォームのカテゴリー選択肢
  CATEGORIES = ["食事", "健康・医療", "住環境・暮らし", "しつけ・行動", "その他"].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 5000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :acceptable_image

  private

  # 画像は形式・サイズを検証（添付が無ければスキップ）
  def acceptable_image
    return unless image.attached?

    unless image.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(:image, "はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    if image.byte_size > 5.megabytes
      errors.add(:image, "は5MB以下にしてください")
    end
  end
end
