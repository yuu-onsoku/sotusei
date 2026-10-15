require 'rails_helper'

RSpec.describe DiagnosisJudge do
  describe ".simple_questions" do
    it "5問読み込める" do
      expect(DiagnosisJudge.simple_questions.size).to eq(5)
    end

    it "すべての質問に文章がある" do
      DiagnosisJudge.simple_questions.each do |q|
        expect(q["text"]).to be_present
      end
    end

    it "すべての選択肢に文章がある" do
      DiagnosisJudge.simple_questions.each do |q|
        q["choices"].each do |c|
          expect(c["text"]).to be_present
        end
      end
    end
  end

  describe "#score" do
    it "すべて最良を選ぶと10点になる" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).score).to eq(10)
    end

    it "すべて真ん中を選ぶと1点になる" do
      answers = { "0" => "1", "1" => "1", "2" => "1", "3" => "1", "4" => "1" }
      expect(DiagnosisJudge.new(answers).score).to eq(1)
    end
  end

  describe "#category_scores" do
    it "カテゴリごとに点数を集計する" do
      # すべて最良（各2点）を選んだ場合
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).category_scores).to eq(
        "生活リズム" => 4,   # 2問 × 2点
        "住環境" => 2,       # 1問 × 2点
        "経済" => 4          # 2問 × 2点
      )
    end

    it "カテゴリごとに弱い部分がわかる" do
      # 1問目だけ最低（-2点）、他は最良
      answers = { "0" => "2", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      scores = DiagnosisJudge.new(answers).category_scores

      expect(scores["生活リズム"]).to eq(0)   # -2 + 2 = 0
      expect(scores["住環境"]).to eq(2)
      expect(scores["経済"]).to eq(4)
    end
  end

  describe "#weak_categories" do
    it "0以下のカテゴリがなければ空になる" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).weak_categories).to be_empty
    end

    it "留守が長く経済も余裕がないと、両方が弱点になる" do
      answers = { "0" => "2", "1" => "1", "2" => "1", "3" => "1", "4" => "1" }
      expect(DiagnosisJudge.new(answers).weak_categories).to eq([ "生活リズム", "経済" ])
    end

    it "複数の弱点があれば両方返す" do
      answers = { "0" => "2", "1" => "1", "2" => "1", "3" => "1", "4" => "2" }
      expect(DiagnosisJudge.new(answers).weak_categories).to eq([ "生活リズム", "経済" ])
    end
  end

  describe "#blocked?" do
    it "blockerを選んでいなければ false" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).blocked?).to be false
    end

    it "ペット不可の住宅を選ぶと true" do
      # 3問目（index 2）の3番目の選択肢（index 2）が blocker
      answers = { "0" => "0", "1" => "0", "2" => "2", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).blocked?).to be true
    end
  end

  describe "#result" do
    it "すべて最良なら準備万端" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).result).to eq("準備万端")
    end

    it "すべて真ん中なら成猫なら可能" do
      answers = { "0" => "1", "1" => "1", "2" => "1", "3" => "1", "4" => "1" }
      expect(DiagnosisJudge.new(answers).result).to eq("成猫なら可能")
    end

    it "blockerを選ぶと点数に関係なく今はまだ早い" do
      # 3問目だけ blocker、他は最良
      answers = { "0" => "0", "1" => "0", "2" => "2", "3" => "0", "4" => "0" }
      expect(DiagnosisJudge.new(answers).result).to eq("今はまだ早い")
    end
  end

  describe "#cat_comments" do
    it "判定に応じたコメントが含まれる" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      comments = DiagnosisJudge.new(answers).cat_comments

      expect(comments).to include(DiagnosisJudge::RESULT_COMMENTS["準備万端"])
    end

    it "弱いカテゴリのコメントが含まれる" do
      # 留守が長く、お金も厳しい
      answers = { "0" => "2", "1" => "1", "2" => "1", "3" => "1", "4" => "2" }
      comments = DiagnosisJudge.new(answers).cat_comments

      expect(comments).to include(DiagnosisJudge::CATEGORY_COMMENTS["生活リズム"])
      expect(comments).to include(DiagnosisJudge::CATEGORY_COMMENTS["経済"])
    end

    it "blockerがあるときは専用コメントだけで、カテゴリのコメントは出ない" do
      # ペット不可の住宅。他は最良なのでカテゴリはマイナスにならない
      answers = { "0" => "0", "1" => "0", "2" => "2", "3" => "0", "4" => "0" }
      comments = DiagnosisJudge.new(answers).cat_comments

      expect(comments).to include(DiagnosisJudge::BLOCKER_COMMENT)
      expect(comments).not_to include(DiagnosisJudge::CATEGORY_COMMENTS["住環境"])
    end
  end

  # 利用者アンケートとLINEで寄せられた声をもとに8問を足した詳細診断。
  # 簡易診断の5問に足す形なので、上のテストはすべてそのまま通る。
  describe "詳細診断（kind: :full）" do
    # 全部の質問で、指定した番号の選択肢を選ぶ
    def answers_all(index, count = DiagnosisJudge.full_questions.size)
      (0...count).to_h { |i| [ i.to_s, index.to_s ] }
    end

    # 境目の判定だけを見たいので、合計点は差し替える。
    # 質問の組み合わせでちょうどの点数を作ろうとすると、質問が増えるたびに作り直しになる
    def judge_with_score(value)
      judge = DiagnosisJudge.new(answers_all(0), kind: :full)
      allow(judge).to receive(:score).and_return(value)
      judge
    end

    # 絶対条件のある選択肢を、質問データから探す。
    # 「何問目の何番目」と書くと、質問を足したときにずれる
    def blocker_answer
      questions = DiagnosisJudge.full_questions
      index = questions.index { |q| q["choices"].any? { |c| c["blocker"] } }
      choice = questions[index]["choices"].index { |c| c["blocker"] }

      { index.to_s => choice.to_s }
    end

    # アンケートはまだ受付中で、質問はこれからも増える。
    # そのため「いま何問か」を書くのはこのテストだけにして、他はここから導く。
    # 質問を足したときに直すのは、このテストの数字だけで済む。
    it "いまの問題数と満点" do
      expect(DiagnosisJudge.simple_questions.size).to eq(5)
      expect(DiagnosisJudge.full_questions.size).to eq(15)
      expect(DiagnosisJudge.new({}, kind: :full).max_score).to eq(30)
    end

    it "詳細診断は、簡易診断の5問を先頭にそのまま含む" do
      simple = DiagnosisJudge.simple_questions

      expect(DiagnosisJudge.full_questions.first(simple.size)).to eq(simple)
    end

    it "指定しなければ簡易診断になる" do
      expect(DiagnosisJudge.new({}).kind).to eq("simple")
      expect(DiagnosisJudge.new({}, kind: "なにこれ").kind).to eq("simple")
    end

    describe "#result" do
      it "全部いちばん良い選択肢なら準備万端" do
        judge = DiagnosisJudge.new(answers_all(0), kind: :full)

        expect(judge.score).to eq(judge.max_score)
        expect(judge.result).to eq("準備万端")
      end

      # 境目を点数で持っていると、質問を足したときに判定が狂う。
      # 満点が何点であっても、その6割を超えたら「準備万端」になること。
      it "満点の6割を境に、判定が切り替わる" do
        max = DiagnosisJudge.new({}, kind: :full).max_score
        border = max * DiagnosisJudge::READY_RATIO

        expect(judge_with_score(border.ceil).result).to eq("準備万端")
        expect(judge_with_score(border.ceil - 1).result).to eq("成猫なら可能")
      end

      it "合計が0点を下回ると今はまだ早い" do
        expect(judge_with_score(0).result).to eq("成猫なら可能")
        expect(judge_with_score(-1).result).to eq("今はまだ早い")
      end

      it "絶対条件にかかると、点数に関係なく今はまだ早い" do
        # 他はすべて最良にしたうえで、絶対条件のある選択肢を1つ選ぶ
        judge = DiagnosisJudge.new(answers_all(0).merge(blocker_answer), kind: :full)

        expect(judge.blocked?).to be true
        expect(judge.result).to eq("今はまだ早い")
      end
    end

    describe "新しいカテゴリ" do
      it "将来と安全のコメントが用意されている" do
        expect(DiagnosisJudge::CATEGORY_COMMENTS).to have_key("将来")
        expect(DiagnosisJudge::CATEGORY_COMMENTS).to have_key("安全")
      end

      # カテゴリを足したのにコメントを書き忘れると、
      # weak_categories に出てきても画面に何も表示されない
      it "すべてのカテゴリにコメントがある" do
        categories = DiagnosisJudge.full_questions.map { |q| q["category"] }.uniq

        expect(categories).to all(satisfy { |c| DiagnosisJudge::CATEGORY_COMMENTS.key?(c) })
      end
    end

    describe "質問データそのもの" do
      it "すべての質問にカテゴリと選択肢がある" do
        DiagnosisJudge.full_questions.each do |question|
          expect(question["text"]).to be_present
          expect(question["category"]).to be_present
          expect(question["choices"]).to be_present
        end
      end

      # score も blocker も無い選択肢は、0点として扱われてしまい、書き忘れに気づけない
      it "すべての選択肢に score か blocker がある" do
        DiagnosisJudge.full_questions.flat_map { |q| q["choices"] }.each do |choice|
          expect(choice.key?("score") || choice["blocker"]).to be_truthy
        end
      end
    end
  end
end
