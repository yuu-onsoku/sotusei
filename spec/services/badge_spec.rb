require 'rails_helper'

RSpec.describe Badge do
  # 称号の判定は users.answers_count の数だけで決まるので、DBに保存しなくても確かめられる
  def user_with(count)
    User.new(answers_count: count)
  end

  # 称号名は RANKS を参照して比べる。こうしておくと、名前や色を直したときに
  # テストを書き換える必要がない（境目の数は「振る舞い」なのでそのまま書く）
  let(:beginner) { Badge::RANKS.last }   # はじめての先輩（1件以上）
  let(:middle)   { Badge::RANKS[1] }     # たよれる先輩（5件以上）
  let(:master)   { Badge::RANKS.first }  # ねこマスター（15件以上）

  describe ".for" do
    it "回答が0件なら称号を出さない" do
      expect(Badge.for(user_with(0))).to be_nil
    end

    # 境目の前後を両方確かめる。片方だけだと「>=」と「>」の間違いに気づけない
    it "1件から4件までは一番下の称号" do
      expect(Badge.for(user_with(1))).to eq(beginner)
      expect(Badge.for(user_with(4))).to eq(beginner)
    end

    it "5件から14件までは真ん中の称号" do
      expect(Badge.for(user_with(5))).to eq(middle)
      expect(Badge.for(user_with(14))).to eq(middle)
    end

    it "15件以上は一番上の称号" do
      expect(Badge.for(user_with(15))).to eq(master)
      expect(Badge.for(user_with(100))).to eq(master)
    end

    it "RANKS は回答数の多い順に並んでいる" do
      # 並びが崩れると、上から探して最初に当てはまったものを返す仕組みが壊れる
      counts = Badge::RANKS.map(&:min_answers)
      expect(counts).to eq(counts.sort.reverse)
    end
  end

  describe ".answers_to_next" do
    it "まだ称号がない人には、最初の称号までの件数を出す" do
      expect(Badge.answers_to_next(user_with(0))).to eq(1)
    end

    it "次の称号まであと1件のときは1を返す" do
      expect(Badge.answers_to_next(user_with(4))).to eq(1)
      expect(Badge.answers_to_next(user_with(14))).to eq(1)
    end

    it "一番上の称号の人には出すものがない" do
      expect(Badge.answers_to_next(user_with(15))).to be_nil
      expect(Badge.answers_to_next(user_with(100))).to be_nil
    end
  end

  # バッジは users.answers_count を見るだけなので、この数が正しく保たれることが前提になる。
  # ここが狂うと、称号の判定が静かに間違う。
  describe "answers_count（counter_cache）" do
    let(:user) { create(:user) }
    let(:question) { create(:question, user: user) }

    it "回答を作ると増え、消すと減る" do
      expect(user.answers_count).to eq(0)

      answer = create(:answer, user: user, question: question)
      expect(user.reload.answers_count).to eq(1)

      answer.destroy
      expect(user.reload.answers_count).to eq(0)
    end
  end
end
