class Question < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable

  belongs_to :user
  has_many :answers, dependent: :destroy

  # 投稿フォームのカテゴリー選択肢
  CATEGORIES = ["食事", "健康・医療", "住環境・暮らし", "しつけ・行動", "その他"].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 5000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
