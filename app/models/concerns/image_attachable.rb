# 任意の添付画像（1枚）を扱うモデル向けの共通処理。
# 形式とサイズを検証し、添付が無ければ何もしない。
module ImageAttachable
  extend ActiveSupport::Concern

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  included do
    has_one_attached :image
    validate :acceptable_image
  end

  private

  # 画像は形式・サイズを検証（添付が無ければスキップ）
  def acceptable_image
    return unless image.attached?

    unless image.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(:image, "はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    if image.byte_size > IMAGE_MAX_SIZE
      errors.add(:image, "は5MB以下にしてください")
    end
  end
end
