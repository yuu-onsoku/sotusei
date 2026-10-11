class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: TagList::MAX_LENGTH }

  # 一覧の上に出す帯の数。多すぎると帯だけで画面が埋まる
  POPULAR_LIMIT = 12

  # よく使われているタグを、使われている数の多い順に。
  # 数が同じときは名前順にして、開くたびに並びが変わらないようにする。
  #
  # order に生のSQLを渡すときは Arel.sql で包む。包まないと Rails が
  # 「カラム名ではないので危ないかもしれない」と判断して止める
  def self.popular
    joins(:post_tags)
      .group(:id)
      .order(Arel.sql("COUNT(post_tags.id) DESC"), :name)
      .limit(POPULAR_LIMIT)
  end
end
