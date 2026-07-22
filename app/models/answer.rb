class Answer < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable
  # いいね（肉球ボタン）
  include Likeable

  belongs_to :question
  belongs_to :user

  validates :content, presence: true, length: { maximum: 5000 }
end
