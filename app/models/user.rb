class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy

  # プロフィール項目のバリデーション（email/password は :validatable が担当）
  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 50 }
end
