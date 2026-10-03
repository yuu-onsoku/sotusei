class Bookmark < ApplicationRecord
  belongs_to :user
  # 今はにゃんスタの投稿だけだが、質問などにも付けられるようにしておく
  belongs_to :bookmarkable, polymorphic: true

  # 同じ対象へのブックマークは1ユーザー1回まで
  validates :user_id, uniqueness: { scope: [ :bookmarkable_type, :bookmarkable_id ] }
end
