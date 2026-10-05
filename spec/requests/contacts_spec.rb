require 'rails_helper'

RSpec.describe "Contacts", type: :request do
  # ログインできない人からの問い合わせも受け取る必要がある
  describe "ログインしていないとき" do
    it "フォームが表示される" do
      get new_contact_path
      expect(response).to have_http_status(:ok)
    end

    it "送信できる" do
      expect {
        post contacts_path, params: { contact: { name: "ねこ太郎", email: "neko@example.com", content: "質問があります" } }
      }.to change(Contact, :count).by(1)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "ログインしているとき" do
    it "返信先が自分のメールアドレスで埋まっている" do
      user = create(:user)
      sign_in user

      get new_contact_path

      expect(response.body).to include(user.email)
    end
  end

  describe "入力に不備があるとき" do
    it "メールアドレスが空だと保存されない" do
      expect {
        post contacts_path, params: { contact: { email: "", content: "質問があります" } }
      }.not_to change(Contact, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "内容が空だと保存されない" do
      expect {
        post contacts_path, params: { contact: { email: "neko@example.com", content: "" } }
      }.not_to change(Contact, :count)
    end
  end

  describe "運営者への通知" do
    it "送信すると通知メールが1通送られる" do
      expect {
        perform_enqueued_jobs do
          post contacts_path, params: { contact: { email: "neko@example.com", content: "質問があります" } }
        end
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "通知メールにそのまま返信すると、問い合わせた人に届く" do
      perform_enqueued_jobs do
        post contacts_path, params: { contact: { email: "neko@example.com", content: "質問があります" } }
      end

      expect(ActionMailer::Base.deliveries.last.reply_to).to eq([ "neko@example.com" ])
    end
  end

  # 規約に「お問い合わせフォームよりご連絡ください」と書いてあるため、
  # リンクが切れていないことを固定する
  describe "規約からの導線" do
    it "利用規約とプライバシーポリシーからお問い合わせへ行ける" do
      get terms_path
      expect(response.body).to include(new_contact_path)

      get privacy_path
      expect(response.body).to include(new_contact_path)
    end

    # 未ログインの人はランディングからしかサイトに触れないため、
    # ここに入口が無いと問い合わせる手段が無くなる
    it "未ログインのトップからお問い合わせへ行ける" do
      get root_path

      expect(response.body).to include(new_contact_path)
      expect(response.body).to include(terms_path)
      expect(response.body).to include(privacy_path)
    end
  end
end
