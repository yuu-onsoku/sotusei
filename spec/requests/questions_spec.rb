require 'rails_helper'

RSpec.describe "Questions", type: :request do
  describe "GET /questions" do
    context "ログインしているとき" do
      it "一覧ページが表示される" do
        user = create(:user)
        sign_in user               # ← ログインさせる（Deviseの機能）
        get questions_path         # ← ページを開く
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていないとき" do
      it "ログイン画面にリダイレクトされる" do
        get questions_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /questions/:id" do
    context "ログインしているとき" do
      it "詳細ページが表示される" do
        user = create(:user)
        question = create(:question)
        sign_in user
        get question_path(question)
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていないとき" do
      it "ログイン画面にリダイレクトされる" do
        question = create(:question)
        get question_path(question)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /questions" do
    context "ログインしていて、入力が正しいとき" do
      it "質問が作成される" do
        user = create(:user)
        sign_in user

        post questions_path, params: {
          question: {
            title: "猫のごはんについて",
            content: "食欲がないのですが、どうすればいいでしょうか。",
            category: "食事"
          }
        }

        expect(Question.count).to eq(1)
        expect(response).to redirect_to(questions_path)
      end
    end

    context "入力が正しくないとき" do
      it "質問が作成されない" do
        user = create(:user)
        sign_in user

        post questions_path, params: {
          question: {
            title: "",
            content: "食欲がないのですが",
            category: "食事"
          }
        }

        expect(Question.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /questions/:id" do
    context "他人の質問を消去しようとしたとき" do
      it "消去されず、一覧にリダイレクトされる" do
        owner = create(:user)
        question = create(:question, user: owner)

        other = create(:user)
        sign_in other

        delete question_path(question)

        expect(Question.count).to eq(1)
        expect(response).to redirect_to(questions_path)
      end
    end
  end

  describe "GET /questions/:id/edit" do
    context "他人の質問のとき" do
      it "編集画面を開けず、一覧にリダイレクトされる" do
        owner = create(:user)
        question = create(:question, user: owner)
        other = create(:user)
        sign_in other
        get edit_question_path(question)
        expect(response).to redirect_to(questions_path)
      end
    end

    context "自分の質問のとき" do
      it "編集画面を開ける" do
        user = create(:user)
        question = create(:question, user: user)
        sign_in user

        get edit_question_path(question)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /questions/:id" do
    context "他人の質問のとき" do
      it "更新できない" do
        owner = create(:user)
        question = create(:question, user: owner, title: "元のタイトル")

        other = create(:user)
        sign_in other

        patch question_path(question), params: {
          question: { title: "書き換えられたタイトル" }
        }

        expect(question.reload.title).to eq("元のタイトル")
        expect(response).to redirect_to(questions_path)
      end
    end

    context "自分の質問のとき" do
      it "更新できる" do
        user = create(:user)
        question = create(:question, user: user, title: "元のタイトル")
        sign_in user

        patch question_path(question), params: {
          question: { title: "新しいタイトル" }
        }

        expect(question.reload.title).to eq("新しいタイトル")
        expect(response).to redirect_to(question_path(question))
      end
    end
  end
  describe "ページ分け" do
    before { sign_in create(:user) }

    it "1ページ目には12件まで出る" do
      create_list(:question, 13)

      get questions_path

      expect(response.body.scan(/questions\/\d+"/).uniq.size).to be <= 12
    end

    it "2ページ目には続きが出る" do
      create_list(:question, 13)
      newest = Question.order(created_at: :desc).first
      oldest = Question.order(created_at: :desc).last

      get questions_path(page: 2)

      expect(response.body).to include(oldest.title)
      expect(response.body).not_to include(newest.title)
    end

    # 範囲外を指定されても画面が壊れないこと
    it "存在しないページでも落ちない" do
      create_list(:question, 3)

      get questions_path(page: 999)

      expect(response).to have_http_status(:ok)
    end

    # 検索したままページを移動できること
    it "検索の言葉がページ送りに引き継がれる" do
      create_list(:question, 13, title: "ねこのごはんについて")

      get questions_path(q: "ごはん")

      expect(response.body).to include("q=")
    end
  end

  # 緊急時の導線。ただの <button> で、押しても何も起きない状態だった。
  # 猫の様子が急変している人が押すボタンなので、ここは落としてはいけない。
  describe "質問の投稿画面の緊急時の案内" do
    before { sign_in create(:user) }

    it "病院検索へのリンクがある" do
      get new_question_path

      expect(response.body).to include(places_path)
    end
  end

  # 以前、この6つのボタンは ただの <button> で、押しても何も起きなかった。
  # しかも「費用」「お迎え前」など、実際には存在しないカテゴリが並んでいた。
  describe "カテゴリでの絞り込み" do
    let(:user) { create(:user) }
    let(:food) { Question::CATEGORIES.first }
    let(:health) { Question::CATEGORIES.second }

    before { sign_in user }

    it "カテゴリを指定すると、そのカテゴリの質問だけが並ぶ" do
      food_question = create(:question, category: food, title: "ごはんの質問です")
      health_question = create(:question, category: health, title: "病院の質問です")

      get questions_path(category: food)

      expect(response.body).to include(food_question.title)
      expect(response.body).not_to include(health_question.title)
    end

    it "指定しなければ全部並ぶ" do
      food_question = create(:question, category: food, title: "ごはんの質問です")
      health_question = create(:question, category: health, title: "病院の質問です")

      get questions_path

      expect(response.body).to include(food_question.title)
      expect(response.body).to include(health_question.title)
    end

    # 画面に直書きしていたせいで、実際のカテゴリとずれていた
    it "画面のカテゴリが CATEGORIES と一致している" do
      get questions_path

      Question::CATEGORIES.each do |category|
        expect(response.body).to include(questions_path(category: category))
      end
    end

    it "検索とカテゴリを同時に使える" do
      hit = create(:question, category: food, title: "カリカリの選び方")
      create(:question, category: health, title: "カリカリと病院の話")

      get questions_path(q: "カリカリ", category: food)

      expect(response.body).to include(hit.title)
      expect(response.body).not_to include("カリカリと病院の話")
    end

    # #148 で、検索したままページを移動できない失敗をしている
    it "検索語とカテゴリの両方がページ送りに引き継がれる" do
      create_list(:question, 13, category: food, title: "ねこのごはんについて")

      get questions_path(q: "ごはん", category: food)

      expect(response.body).to include("q=")
      expect(response.body).to include("category=")
    end

    it "存在しないカテゴリ名でも画面が壊れない" do
      get questions_path(category: "費用")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("見つかりませんでした").or include("まだありません")
    end
  end

  describe "回答者のバッジ" do
    let(:user) { create(:user) }
    before { sign_in user }

    it "回答を重ねた人の称号が、回答の横に出る" do
      veteran = create(:user)
      question = create(:question, user: user)
      # 5件答えると真ん中の称号になる
      create_list(:question, 5).each { |q| create(:answer, user: veteran, question: q) }
      create(:answer, user: veteran, question: question, content: "こう思いますよ")

      get question_path(question)

      expect(response.body).to include(Badge::RANKS[1].name)
    end

    it "まだ回答していない人の回答には称号が出ない" do
      newcomer = create(:user)
      question = create(:question, user: user)
      create(:answer, user: newcomer, question: question, content: "はじめて答えます")

      get question_path(question)

      # 1件目の回答なので一番下の称号になり、真ん中の称号は出ない
      expect(response.body).to include(Badge::RANKS.last.name)
      expect(response.body).not_to include(Badge::RANKS[1].name)
    end
  end
end
