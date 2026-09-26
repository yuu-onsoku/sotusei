require 'rails_helper'

RSpec.describe "Diagnoses", type: :request do
  describe "GET /diagnoses/new" do
    it "ログインしていなくても質問画面が表示される" do
      get new_diagnosis_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /diagnoses" do
    it "回答を送ると結果画面にリダイレクトされる" do
      answers = { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" }
      post diagnoses_path, params: { answers: answers }
      expect(response).to redirect_to(result_diagnoses_path)
    end
  end

  describe "GET /diagnoses/result" do
    it "診断していない場合は質問画面に戻される" do
      get result_diagnoses_path
      expect(response).to redirect_to(new_diagnosis_path)
    end
  end
end
