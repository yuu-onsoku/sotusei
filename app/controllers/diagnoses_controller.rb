class DiagnosesController < ApplicationController
  # 簡易診断は入口機能のため、ログイン不要で使える。
  # 詳細診断は結果を履歴として残すものなので、ログインを求める
  before_action :authenticate_user!, if: -> { kind == "full" }

  # 質問画面
  def new
    @kind = kind
    @questions = DiagnosisJudge.questions_for(kind)
  end

  # 回答を受け取って判定し、結果画面へ移動する
  def create
    judge = DiagnosisJudge.new(answers_params, kind: kind)

    # ログイン中なら履歴として残す。未ログインでも今までどおり使える。
    if user_signed_in?
      current_user.diagnoses.create(answers: answers_params, score: judge.score,
                                    result: judge.result, kind: kind)
    end

    session[:diagnosis] = {
      "score" => judge.score,
      "max_score" => judge.max_score,
      "result" => judge.result,
      "comments" => judge.cat_comments,
      "kind" => kind
    }
    redirect_to result_diagnoses_path
  end

  # 判定結果を表示する
  def result
    diagnosis = session[:diagnosis]
    return redirect_to new_diagnosis_path if diagnosis.blank?

    @score = diagnosis["score"]
    # 以前の形式のセッションが残っている場合に備えて、無ければ簡易診断とみなす
    @max_score = diagnosis["max_score"] || DiagnosisJudge.new({}).max_score
    @result = diagnosis["result"]
    @comments = diagnosis["comments"]
    @kind = diagnosis["kind"] || "simple"
  end

  private

  # 簡易診断と詳細診断のどちらか。知らない値は簡易診断として扱う
  def kind
    params[:kind] == "full" ? "full" : "simple"
  end

  # 回答は { "0" => "1", "1" => "0", ... } の形で届く
  # 質問の数だけキーを明示的に許可する（permit! は何でも通してしまうため使わない）
  def answers_params
    keys = DiagnosisJudge.questions_for(kind).each_index.map(&:to_s)
    params.fetch(:answers, {}).permit(*keys).to_h
  end
end
