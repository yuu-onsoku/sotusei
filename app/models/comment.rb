class Comment < ApplicationRecord
  belongs_to :user
  # 質問にも回答にもコメントできる
  belongs_to :commentable, polymorphic: true
  validates :content, presence: true, length: { maximum: 1000 }
end
