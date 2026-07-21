class Answer < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable

  belongs_to :question
  belongs_to :user

  validates :content, presence: true, length: { maximum: 5000 }
end
