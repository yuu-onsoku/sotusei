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

  describe "詳細診断（13問）" do
    def full_answers(index = 0)
      (0...13).to_h { |i| [ i.to_s, index.to_s ] }
    end

    # 簡易診断は入口機能なのでログイン不要のまま。詳細診断だけログインを求める
    it "未ログインでは開けない" do
      get new_diagnosis_path(kind: "full")

      expect(response).to redirect_to(new_user_session_path)
    end

    describe "ログインしているとき" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "13問が表示される" do
        get new_diagnosis_path(kind: "full")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("13つの質問")
      end

      # kind をフォームに入れ忘れると、送信後に簡易診断として採点されてしまう
      it "フォームの送信先に kind=full が入っている" do
        get new_diagnosis_path(kind: "full")

        expect(response.body).to include("kind=full")
      end

      it "詳細診断として保存される" do
        expect {
          post diagnoses_path(kind: "full"), params: { answers: full_answers }
        }.to change(Diagnosis, :count).by(1)

        diagnosis = Diagnosis.last
        expect(diagnosis.kind).to eq("full")
        expect(diagnosis.score).to eq(26)
        expect(diagnosis.result).to eq("準備万端")
      end

      # 「20点 / 10点満点」のような表示にならないこと
      it "結果画面の満点が26点になる" do
        post diagnoses_path(kind: "full"), params: { answers: full_answers }
        follow_redirect!

        expect(response.body).to include("26点満点")
      end

      it "簡易診断の結果画面から、詳細診断への導線がある" do
        post diagnoses_path, params: { answers: { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" } }
        follow_redirect!

        expect(response.body).to include(new_diagnosis_path(kind: "full"))
      end

      it "詳細診断の結果画面には、詳細診断への導線を出さない" do
        post diagnoses_path(kind: "full"), params: { answers: full_answers }
        follow_redirect!

        expect(response.body).not_to include(new_diagnosis_path(kind: "full"))
      end
    end
  end

  # 診断を保存したあとに質問を増やしても、マイページが壊れないこと
  describe "マイページの診断履歴" do
    let(:user) { create(:user) }
    before { sign_in user }

    it "簡易診断は10点満点、詳細診断は26点満点と出る" do
      create(:diagnosis, user: user, kind: "simple", score: 8)
      get mypage_path(tab: "diagnoses")
      expect(response.body).to include("10点満点")

      Diagnosis.destroy_all
      create(:diagnosis, user: user, kind: "full",
             answers: (0...13).to_h { |i| [ i.to_s, "0" ] }, score: 26)
      get mypage_path(tab: "diagnoses")
      expect(response.body).to include("26点満点")
    end
  end
end
