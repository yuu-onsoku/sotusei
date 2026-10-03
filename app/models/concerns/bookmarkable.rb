# ブックマークを受け取れるモデル向けの共通処理。
module Bookmarkable
  extend ActiveSupport::Concern

  included do
    has_many :bookmarks, as: :bookmarkable, dependent: :destroy
  end

  # このユーザーが保存済みかどうか（読み込み済みの bookmarks を使うので一覧でも追加クエリなし）
  def bookmarked_by?(user)
    return false if user.blank?

    bookmarks.any? { |bookmark| bookmark.user_id == user.id }
  end
end
