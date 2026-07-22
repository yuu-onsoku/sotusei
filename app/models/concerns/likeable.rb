# いいね（肉球ボタン）を受け取れるモデル向けの共通処理。
module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  # このユーザーがいいね済みかどうか（読み込み済みの likes を使うので一覧でも追加クエリなし）
  def liked_by?(user)
    return false if user.blank?

    likes.any? { |like| like.user_id == user.id }
  end
end
