require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  def image_file
    fixture_file_upload("spec/fixtures/files/test_image.png", "image/png")
  end

  it "ログインしていないと編集画面を開けない" do
    get edit_profile_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "ログインしているとき" do
    let(:user) { create(:user) }
    before { sign_in user }

    it "編集画面が表示される" do
      get edit_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "ユーザー名とお名前を変えられる" do
      patch profile_path, params: { user: { username: "あたらしい名前", name: "ねこ太郎" } }

      user.reload
      expect(user.username).to eq("あたらしい名前")
      expect(user.name).to eq("ねこ太郎")
      expect(response).to redirect_to(mypage_path)
    end

    it "アイコンを設定できる" do
      patch profile_path, params: { user: { username: user.username, avatar: image_file } }

      expect(user.reload.avatar).to be_attached
    end

    # 画像をえらばずに送ると avatar が "" で届く。
    # そのまま渡すと今のアイコンが消えるため、コントローラで取り除いている。
    it "画像をえらばずに保存しても、アイコンが消えない" do
      patch profile_path, params: { user: { username: user.username, avatar: image_file } }
      expect(user.reload.avatar).to be_attached

      patch profile_path, params: { user: { username: "名前だけ変える", avatar: "" } }

      expect(user.reload.avatar).to be_attached
      expect(user.username).to eq("名前だけ変える")
    end

    it "チェックを入れるとアイコンを外せる" do
      patch profile_path, params: { user: { username: user.username, avatar: image_file } }
      expect(user.reload.avatar).to be_attached

      patch profile_path, params: { remove_avatar: "1", user: { username: user.username } }

      expect(user.reload.avatar).not_to be_attached
    end

    it "ユーザー名を空にすると保存されない" do
      patch profile_path, params: { user: { username: "" } }

      expect(user.reload.username).to be_present
      expect(response).to have_http_status(:unprocessable_content)
    end

    # パスワードを聞かれずに変更できることが、この画面を分けた理由
    it "現在のパスワードを入力しなくても変更できる" do
      patch profile_path, params: { user: { name: "パスワードなしで変更" } }

      expect(user.reload.name).to eq("パスワードなしで変更")
    end
  end
end
