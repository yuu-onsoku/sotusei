class DiagnosesController < ApplicationController
  # 診断は入口機能のため、ログイン不要で使える

  # 質問画面
  def new
    @questions = DiagnosisJudge.simple_questions
  end

  # 回答を受け取って判定し、結果画面へ移動する
  def create
    judge = DiagnosisJudge.new(answers_params)

    # ログイン中なら履歴として残す。未ログインでも今までどおり使える。
    if user_signed_in?
      current_user.diagnoses.create(answers: answers_params, score: judge.score, result: judge.result)
    end

    session[:diagnosis] = {
      "score" => judge.score,
      "result" => judge.result,
      "comments" => judge.cat_comments
    }
    redirect_to result_diagnoses_path
  end

  # 判定結果を表示する
  def result
    diagnosis = session[:diagnosis]
    return redirect_to new_diagnosis_path if diagnosis.blank?

    @score = diagnosis["score"]
    @result = diagnosis["result"]
    @comments = diagnosis["comments"]       # ← 追加
  end

  private

  # 回答は { "0" => "1", "1" => "0", ... } の形で届く
  # 質問の数だけキーを明示的に許可する（permit! は何でも通してしまうため使わない）
  def answers_params
    keys = DiagnosisJudge.simple_questions.each_index.map(&:to_s)
    params.fetch(:answers, {}).permit(*keys).to_h
  end
end
