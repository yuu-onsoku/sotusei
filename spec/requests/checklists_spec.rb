require 'rails_helper'

RSpec.describe "Checklists", type: :request do
  describe "ログインしていないとき" do
    it "ログイン画面にリダイレクトされる" do
      get new_checklist_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログインしているとき" do
    before { sign_in create(:user) }

    describe "GET /checklists/new" do
      it "チェックリストが表示される" do
        get new_checklist_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /checklists" do
      it "チェックを送ると結果画面にリダイレクトされる" do
        post checklists_path, params: { checklist: { checked: [ "0", "1" ] } }
        expect(response).to redirect_to(result_checklists_path)
      end

      it "1つもチェックしなくても結果画面にリダイレクトされる" do
        post checklists_path
        expect(response).to redirect_to(result_checklists_path)
      end
    end

    describe "GET /checklists/result" do
      it "チェックを送っていない場合はチェックリストに戻される" do
        get result_checklists_path
        expect(response).to redirect_to(new_checklist_path)
      end

      # 「1つもチェックしない」は勇気ある決断であり、ちゃんとした回答。
      # session が [] のとき blank? で判定すると質問画面に追い返してしまうため、
      # コントローラでは nil? を使っている。その約束をここで守る。
      it "1つもチェックしなくても結果が見られる" do
        post checklists_path
        get result_checklists_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("16個のうち、0個")
      end

      it "全部チェックすると覚悟ができたことが伝わる" do
        post checklists_path, params: { checklist: { checked: (0..15).map(&:to_s) } }
        get result_checklists_path

        expect(response.body).to include("覚悟はできているにゃ")
      end
    end
  end
end
