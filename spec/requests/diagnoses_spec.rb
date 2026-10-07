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
    # 診断からチェックリストへの流れが、このアプリの中心。
    # リンクを消しても画面もテストも壊れないため、ここで固定する。
    it "診断結果からチェックリストへの導線がある" do
      post diagnoses_path, params: { answers: { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" } }
      get result_diagnoses_path
      expect(response.body).to include(new_checklist_path)
    end
  end

  describe "履歴の保存" do
    let(:answers) { { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" } }

    it "ログイン中は履歴が残る" do
      sign_in create(:user)

      expect {
        post diagnoses_path, params: { answers: answers }
      }.to change(Diagnosis, :count).by(1)

      expect(Diagnosis.last.result).to eq("準備万端")
      expect(Diagnosis.last.answers).to eq(answers)
    end

    # 診断は未ログインでも使える入口機能。保存されないだけで、結果は出る。
    it "未ログインでは保存されないが、結果は見られる" do
      expect {
        post diagnoses_path, params: { answers: answers }
      }.not_to change(Diagnosis, :count)

      expect(response).to redirect_to(result_diagnoses_path)
    end
  end
end
