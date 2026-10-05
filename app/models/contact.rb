class Contact < ApplicationRecord
  validates :name, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  # 返信できないと困るので、ドメインにドットがあることも確かめる（gmail のような打ち間違い対策）
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, message: "の形式が正しくありません" },
                    allow_blank: true
  validates :content, presence: true, length: { maximum: 2000 }
end
