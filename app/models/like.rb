class Like < ApplicationRecord
  belongs_to :user
  # 質問にも回答にもいいねできる
  belongs_to :likeable, polymorphic: true

  # 同じ対象へのいいねは1ユーザー1回まで
  validates :user_id, uniqueness: { scope: [ :likeable_type, :likeable_id ] }
end
