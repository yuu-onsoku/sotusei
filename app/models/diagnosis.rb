class Diagnosis < ApplicationRecord
  belongs_to :user

  validates :answers, presence: true
  validates :score, presence: true
  validates :result, presence: true

  # 保存した回答から、判定し直す係を作る。
  # 「どのカテゴリが弱かったか」などは、ここから取り出す。
  def judge
    DiagnosisJudge.new(answers)
  end
end
