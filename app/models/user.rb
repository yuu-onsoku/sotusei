class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :bookmarks, dependent: :destroy

  # プロフィールのアイコン（任意）
  has_one_attached :avatar

  # プロフィール項目のバリデーション（email/password は :validatable が担当）
  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 50 }
  validate :acceptable_avatar

  private

  # アイコンは形式とサイズを検証（設定していなければ何もしない）
  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, "はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "は5MB以下にしてください")
    end
  end
end
