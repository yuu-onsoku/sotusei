class DiagnosesController < ApplicationController
  # 診断は入口機能のため、ログイン不要で使える

  # 質問画面
  def new
    @questions = DiagnosisJudge.simple_questions
  end

  # 回答を受け取って判定し、結果画面へ移動する
  def create
    judge = DiagnosisJudge.new(answers_params)
    session[:diagnosis] = { "score" => judge.score, "result" => judge.result }
    redirect_to result_diagnoses_path
  end

  # 判定結果を表示する
  def result
    diagnosis = session[:diagnosis]
    # 診断していない人が直接URLを開いた場合は、質問画面へ戻す
    return redirect_to new_diagnosis_path if diagnosis.blank?

    @score = diagnosis["score"]
    @result = diagnosis["result"]
  end

  private

  # 回答は { "0" => "1", "1" => "0", ... } の形で届く
  def answers_params
    params.fetch(:answers, {}).permit!.to_h
  end
end
