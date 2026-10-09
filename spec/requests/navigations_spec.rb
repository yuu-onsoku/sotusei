require 'rails_helper'

# ナビは各ページが別々に持っていて中身がバラバラだった。
# 共通部品にまとめたので、どのページでも同じものが出ることを固定する。
RSpec.describe "ナビゲーション", type: :request do
  describe "ログインしているとき" do
    before { sign_in create(:user) }

    # 下部タブはレイアウトに置いたので、全ページに出る
    it "どのページにも下部タブが出る" do
      [ root_path, questions_path, posts_path, new_checklist_path,
        new_diagnosis_path, mypage_path, bookmarks_path, places_path ].each do |path|
        get path
        expect(response.body).to include("メインメニュー"), "#{path} に下部タブが無い"
      end
    end

    it "上部ナビを持つページでは、6つの行き先がすべて出る" do
      paths = [ root_path, questions_path ]
      links = [ new_diagnosis_path, new_checklist_path, places_path,
                questions_path, posts_path, mypage_path ]

      paths.each do |path|
        get path
        links.each do |link|
          expect(response.body).to include(link), "#{path} に #{link} が無い"
        end
      end
    end

    it "どのページからでもログアウトできる" do
      get questions_path
      expect(response.body).to include(destroy_user_session_path)
    end
  end

  # 下部タブはログイン後の機能への入口なので、未ログインには出さない
  it "ログインしていないときは下部タブが出ない" do
    get root_path
    expect(response.body).not_to include("メインメニュー")
  end
end
