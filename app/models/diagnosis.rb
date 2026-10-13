class Diagnosis < ApplicationRecord
  KINDS = %w[simple full].freeze

  belongs_to :user

  validates :answers, presence: true
  validates :score, presence: true
  validates :result, presence: true
  validates :kind, inclusion: { in: KINDS }

  # 保存した回答から、判定し直す係を作る。
  # 「どのカテゴリが弱かったか」などは、ここから取り出す。
  def judge
    DiagnosisJudge.new(answers, kind: kind)
  end

  # 満点。簡易診断は10点、詳細診断は26点。
  # 画面に「◯点満点」と直書きすると、質問を足したときにずれる
  def max_score
    judge.max_score
  end

  def full?
    kind == "full"
  end
end
