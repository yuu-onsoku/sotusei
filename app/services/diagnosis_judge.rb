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
    "経済"       => "ごはんや病院代が足りるか、ちょっと心配だにゃ（おやつも欲しいしにゃ～）"
  }.freeze

  # 絶対条件に引っかかった場合のひとこと
  BLOCKER_COMMENT = "今のままでは、一緒に暮らすことができないにゃ。まずはそこを整えてほしいにゃ"


  def self.simple_questions
    QUESTIONS["simple"]
  end

  # answers は { "0" => "1", "1" => "0", ... } の形
  # （キーが質問の番号、値が選んだ選択肢の番号）
  def initialize(answers)
    @answers = answers
  end

  # 選ばれた選択肢を順番に取り出す
  def selected_choices
    self.class.simple_questions.each_with_index.map do |question, index|
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
    self.class.simple_questions.zip(selected_choices).each_with_object({}) do |(question, choice), scores|
      category = question["category"]
      scores[category] = (scores[category] || 0) + choice["score"].to_i
    end
  end

  # 点数がマイナスのカテゴリを返す（点数が低い順）
  # => ["経済", "生活リズム"]
  def weak_categories
    category_scores.select { |_category, score| score.negative? }
                   .sort_by { |_category, score| score }
                   .map(&:first)
  end


  # 絶対条件を満たしていない選択肢が1つでもあるか
  def blocked?
    selected_choices.any? { |choice| choice["blocker"] }
  end

  # 判定結果を返す
  def result
    return "今はまだ早い" if blocked?

    case score
    when 6..    then "準備万端"
    when 0..5   then "成猫なら可能"
    else             "今はまだ早い"
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
