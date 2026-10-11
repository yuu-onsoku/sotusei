# 回答数に応じた称号（バッジ）を決める係。
#
# ねこの相談室は、質問する人だけでは成り立たない。答える側に何も返らないと
# 続けてもらえないため、回答を重ねた人が目に見えて報われる形を作る。
#
# 称号名・境目・色・アイコンはこのクラスだけにまとめてある。
# そのため、文章や色を直してもテストを書き換えなくてよい。
class Badge
  Rank = Struct.new(:name, :min_answers, :icon, :chip_class, :ring_class, keyword_init: true)

  # 上から順に調べ、最初に当てはまったものを返す（＝高い称号を優先するため降順に並べる）
  RANKS = [
    Rank.new(
      name: "ねこマスター",
      min_answers: 15,
      icon: "workspace_premium",
      chip_class: "bg-badge-gold text-on-badge-gold",
      ring_class: "ring-4 ring-badge-gold"
    ),
    Rank.new(
      name: "たよれる先輩",
      min_answers: 5,
      icon: "favorite",
      chip_class: "bg-badge-silver text-on-badge-silver",
      ring_class: "ring-[3px] ring-badge-silver"
    ),
    Rank.new(
      name: "はじめての先輩",
      min_answers: 1,
      icon: "pets",
      chip_class: "bg-badge-bronze text-on-badge-bronze",
      ring_class: "ring-2 ring-badge-bronze"
    )
  ].freeze

  # 回答が0件の人には称号を出さない（nil を返す）。
  # 数は users.answers_count（counter_cache）から取るので、関連をたどらずN+1にならない。
  def self.for(user)
    RANKS.find { |rank| user.answers_count >= rank.min_answers }
  end

  # 次の称号まであと何件か。いちばん上の称号の人には nil を返す（出すものがない）
  def self.answers_to_next(user)
    # RANKS は多い順なので、reverse で少ない順にして「まだ届いていない最初の称号」を探す
    next_rank = RANKS.reverse.find { |rank| user.answers_count < rank.min_answers }
    next_rank && next_rank.min_answers - user.answers_count
  end
end
