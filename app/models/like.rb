class Like < ApplicationRecord
  belongs_to :user
  belongs_to :question

  # 同じ投稿へのいいねは1ユーザー1回まで
  validates :user_id, uniqueness: { scope: :question_id }
end
