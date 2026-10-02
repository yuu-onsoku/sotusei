# コメントを受け取れるモデル向けの共通処理。
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
  end
end
