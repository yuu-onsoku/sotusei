class Answer < ApplicationRecord
  # 添付画像（任意）
  include ImageAttachable
  # いいね（肉球ボタン）
  include Likeable

  # コメント
  include Commentable

  belongs_to :question
  #  質問機能にいいねと画像挿入
  #  ユーザーにもいいねと画像添付
  # 回答が増減したら users.answers_count も一緒に更新させる（バッジの判定に使う）
  belongs_to :user, counter_cache: true

  validates :content, presence: true, length: { maximum: 5000 }
  #  つまり「**回答の本文は、空でなく、5000文字以内でなければ保存できない**」というルールです。5001文字目からはだめで、0文字（空）もダメである
end
