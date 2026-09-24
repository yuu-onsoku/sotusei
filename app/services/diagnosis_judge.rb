# app/services/diagnosis_judge.rb
class DiagnosisJudge
  # 質問データ（起動時に1度だけ読み込む）
  QUESTIONS = YAML.load_file(Rails.root.join("config/diagnosis_questions.yml")).freeze

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
end
