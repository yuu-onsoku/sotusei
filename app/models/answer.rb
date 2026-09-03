class Answer < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable
  # いいね（肉球ボタン）
  include Likeable

  belongs_to :question
  #  質問機能にいいねと画像挿入
  belongs_to :user
  #  ユーザーにもいいねと画像添付

  validates :content, presence: true, length: { maximum: 5000 }
  #  つまり「**回答の本文は、空でなく、5000文字以内でなければ保存できない**」というルールです。5001文字目からはだめで、0文字（空）もダメである
end
