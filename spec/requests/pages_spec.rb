require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /terms" do
    it "ログインしていなくても利用規約が表示される" do
      get terms_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /privacy" do
    it "ログインしていなくてもプライバシーポリシーが表示される" do
      get privacy_path
      expect(response).to have_http_status(:ok)
    end
  end

  # 登録画面には「利用規約とプライバシーポリシーに同意します」と書いてある。
  # リンクが切れていると、読まずに同意させることになるため、ここで固定する。
  describe "登録画面からの導線" do
    it "利用規約とプライバシーポリシーへのリンクがある" do
      get new_user_registration_path

      expect(response.body).to include(terms_path)
      expect(response.body).to include(privacy_path)
    end
  end
end
