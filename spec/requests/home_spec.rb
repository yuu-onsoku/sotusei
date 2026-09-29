require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "ログインしていないとき" do
      it "ランディングページが表示される" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "診断へのリンクがある" do
        get root_path
        expect(response.body).to include(new_diagnosis_path)
      end

      it "ログイン・新規登録へのリンクがある" do
        get root_path
        expect(response.body).to include(new_user_session_path)
        expect(response.body).to include(new_user_registration_path)
      end
    end

    context "ログインしているとき" do
      it "コミュニティのトップページが表示される" do
        user = create(:user)
        sign_in user

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ログアウト")
      end
    end
  end
end
