# app/services/diagnosis_judge.rb
class DiagnosisJudge
  # 質問データ（起動時に1度だけ読み込む）
  QUESTIONS = YAML.load_file(Rails.root.join("config/diagnosis_questions.yml")).freeze

  # 判定ごとの猫からのひとこと
  RESULT_COMMENTS = {
    "準備万端"     => "やったにゃ！いつでも会いに行けそうだにゃ～",
    "成猫なら可能" => "子猫はちょっと大変かもにゃんね…おとなの猫となら、一緒に暮らせそうだにゃ",
    "今はまだ早い" => "今はまだ、ねこたちを迎える準備ができていないみたいだにゃ…準備できるまで待てするにゃ！"
  }.freeze

  # 気になるカテゴリごとのひとこと
  CATEGORY_COMMENTS = {
    "生活リズム" => "ひとりでお留守番する時間が長いと、さみしいにゃ…",
    "住環境"     => "安心して過ごせるおうちかどうか、気になるにゃ",
    "経済"       => "ごはんや病院代が足りるか、ちょっと心配だにゃ（おやつも欲しいしにゃ～）",
    "将来"       => "この先なにがあっても、そばにいてくれるか心配だにゃ…",
    "安全"       => "おうちの中に、食べちゃいけないものが落ちてないか気になるにゃ",
    "お世話"     => "毎日のお世話、ちゃんとしてもらえるか気になるにゃ…"
  }.freeze

  # 「準備万端」とみなす割合。満点の6割以上。
  # 点数そのものではなく割合にしているので、質問を足しても境目が付いてくる
  READY_RATIO = 0.6

  # 絶対条件に引っかかった場合のひとこと
  BLOCKER_COMMENT = "今のままでは、一緒に暮らすことができないにゃ。まずはそこを整えてほしいにゃ"


  # ログイン不要の簡易診断（5問）
  def self.simple_questions
    QUESTIONS["simple"]
  end

  # ログイン後の詳細診断（13問）。簡易診断の5問に、追加の8問を足したもの
  def self.full_questions
    QUESTIONS["simple"] + QUESTIONS["additional"]
  end

  def self.questions_for(kind)
    kind.to_s == "full" ? full_questions : simple_questions
  end

  attr_reader :kind

  # answers は { "0" => "1", "1" => "0", ... } の形
  # （キーが質問の番号、値が選んだ選択肢の番号）
  def initialize(answers, kind: :simple)
    @answers = answers
    @kind = kind.to_s == "full" ? "full" : "simple"
  end

  def questions
    self.class.questions_for(@kind)
  end

  # 選ばれた選択肢を順番に取り出す
  def selected_choices
    questions.each_with_index.map do |question, index|
      choice_index = @answers[index.to_s].to_i
      question["choices"][choice_index]
    end
  end

  def score
    selected_choices.sum { |choice| choice["score"].to_i }
  end

  # カテゴリごとの合計点を返す
  # => { "生活リズム" => -2, "住環境" => 2, "経済" => 0 }
  def category_scores
    questions.zip(selected_choices).each_with_object({}) do |(question, choice), scores|
      category = question["category"]
      scores[category] = (scores[category] || 0) + choice["score"].to_i
    end
  end

  # 点数が0以下のカテゴリを返す（点数が低い順）
  # 0点は「可もなく不可もない」状態だが、猫にとっては十分とは言えないため弱点に含める
  # => ["経済", "生活リズム"]
  def weak_categories
    category_scores.select { |_category, score| score <= 0 }
                   .sort_by { |_category, score| score }
                   .map(&:first)
  end



  # 絶対条件を満たしていない選択肢が1つでもあるか
  def blocked?
    selected_choices.any? { |choice| choice["blocker"] }
  end

  # 全部いちばん良い選択肢を選んだときの点数。
  # 簡易診断は10点、詳細診断は26点になる
  def max_score
    questions.sum { |question| question["choices"].map { |choice| choice["score"].to_i }.max }
  end

  # 判定結果を返す。
  # 境目は点数ではなく満点に対する割合で決めているので、質問を足しても調整が要らない
  # （5問のときの「6点以上＝準備万端」は、満点10点の6割にあたる）
  def result
    return "今はまだ早い" if blocked?

    case score
    when (max_score * READY_RATIO).. then "準備万端"
    when 0..                         then "成猫なら可能"
    else                                  "今はまだ早い"
    end
  end

  # 猫からのコメントを組み立てて返す
  # => ["今はまだ早いにゃ…", "ひとりでお留守番する時間が長いと、さみしいにゃ…"]
  def cat_comments
    comments = [ RESULT_COMMENTS[result] ]

    if blocked?
      comments << BLOCKER_COMMENT
    else
      weak_categories.each { |category| comments << CATEGORY_COMMENTS[category] }
    end

    comments.compact
  end
end
