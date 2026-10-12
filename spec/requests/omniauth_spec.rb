require 'rails_helper'

# Googleアカウントでのログイン。
# OmniAuth.config.test_mode が有効なので、Googleには実際に通信せず、
# ここで用意した返事（mock_auth）が返ってくる。
# PlaceSearch のテストでスタブを使ったのと同じ考え方。
RSpec.describe "Googleアカウントでのログイン", type: :request do
  # Googleが返してくる形。email_verified は extra.raw_info の中に入ってくる
  def google_auth(email:, uid: "1234567890", name: "ねこ好き太郎", verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  def sign_in_with(auth)
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    post user_google_oauth2_omniauth_authorize_path
    follow_redirect!   # /users/auth/google_oauth2/callback へ
  end

  describe "はじめての人" do
    it "ユーザーが作られてログインできる" do
      expect {
        sign_in_with(google_auth(email: "neko@example.com"))
      }.to change(User, :count).by(1)

      user = User.last
      expect(user.email).to eq("neko@example.com")
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("1234567890")
      expect(response).to redirect_to(root_path)
    end

    it "Googleの表示名がユーザー名になる" do
      sign_in_with(google_auth(email: "neko@example.com", name: "みかん"))

      expect(User.last.username).to eq("みかん")
    end

    it "同じ名前の人がいたら番号が足される" do
      create(:user, username: "みかん")

      sign_in_with(google_auth(email: "neko@example.com", name: "みかん"))

      expect(User.last.username).to eq("みかん2")
    end

    it "表示名が無ければメールアドレスの@より前を使う" do
      sign_in_with(google_auth(email: "shiro@example.com", name: nil))

      expect(User.last.username).to eq("shiro")
    end
  end

  describe "2回目以降" do
    it "同じユーザーとしてログインし、増えない" do
      sign_in_with(google_auth(email: "neko@example.com"))
      expect(User.count).to eq(1)

      delete destroy_user_session_path

      expect {
        sign_in_with(google_auth(email: "neko@example.com"))
      }.not_to change(User, :count)
    end

    # uid はメールアドレスを変えても変わらない識別子なので、こちらを先に見ている
    it "Google側でメールアドレスが変わっても、同じユーザーとして扱う" do
      sign_in_with(google_auth(email: "old@example.com", uid: "same-uid"))
      user = User.last
      delete destroy_user_session_path

      expect {
        sign_in_with(google_auth(email: "new@example.com", uid: "same-uid"))
      }.not_to change(User, :count)

      expect(User.last).to eq(user)
    end
  end

  describe "すでにパスワードで登録している人" do
    # 方式A：同じメールアドレスなら同じ人として、既存のアカウントに紐づける。
    # 別アカウントを作ると、質問や投稿が2つに分かれてしまう
    it "既存のアカウントに紐づけられ、新しく作られない" do
      existing = create(:user, email: "neko@example.com")

      expect {
        sign_in_with(google_auth(email: "neko@example.com"))
      }.not_to change(User, :count)

      existing.reload
      expect(existing.provider).to eq("google_oauth2")
      expect(existing.uid).to eq("1234567890")
    end

    it "紐づけたあとも、パスワードでログインできる" do
      existing = create(:user, email: "neko@example.com", password: "password")
      sign_in_with(google_auth(email: "neko@example.com"))
      delete destroy_user_session_path

      post user_session_path, params: { user: { email: "neko@example.com", password: "password" } }

      expect(response).to redirect_to(root_path)
      expect(existing.reload.username).to be_present
    end
  end

  describe "⚠️ 本人確認済みでないメールアドレス" do
    # ここを省くと、他人のメールアドレスを名乗られたときに
    # そのアカウントに入れてしまう。このテストがこの機能の要
    it "Googleが確認済みと言っていなければログインできない" do
      expect {
        sign_in_with(google_auth(email: "neko@example.com", verified: false))
      }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "確認済みでなければ、既存アカウントにも入れない" do
      existing = create(:user, email: "neko@example.com")

      sign_in_with(google_auth(email: "neko@example.com", verified: false))

      expect(response).to redirect_to(new_user_session_path)
      expect(existing.reload.provider).to be_nil
    end

    it "メールアドレスが取れなければログインできない" do
      expect {
        sign_in_with(google_auth(email: nil))
      }.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "Googleの画面でキャンセルしたとき" do
    it "エラー画面ではなくログイン画面に戻る" do
      OmniAuth.config.mock_auth[:google_oauth2] = :access_denied
      post user_google_oauth2_omniauth_authorize_path
      follow_redirect!

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
