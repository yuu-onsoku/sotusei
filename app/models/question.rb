class Question < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable
  # いいね（肉球ボタン）
  include Likeable

  belongs_to :user
  has_many :answers, dependent: :destroy

  # 投稿フォームのカテゴリー選択肢
  CATEGORIES = [ "食事", "健康・医療", "住環境・暮らし", "しつけ・行動", "その他" ].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 5000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  # タイトルまたは本文にキーワードを含む質問（キーワードが空なら全件）
  def self.search(keyword)
    keyword = keyword.to_s.strip
    return all if keyword.blank?

    where("title ILIKE :pattern OR content ILIKE :pattern", pattern: "%#{sanitize_sql_like(keyword)}%")
  end
end
