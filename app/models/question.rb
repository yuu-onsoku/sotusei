class Question < ApplicationRecord
  belongs_to :user

  # 投稿フォームのカテゴリー選択肢
  CATEGORIES = ["食事", "健康・医療", "住環境・暮らし", "しつけ・行動", "その他"].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 5000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
