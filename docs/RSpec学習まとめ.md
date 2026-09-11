# Rails 8 + RSpec 学習まとめ

猫コミュニティアプリ（卒業制作）に RSpec を導入し、モデル・ヘルパー・リクエストのテストを56本書くまでの記録。
カバレッジは SimpleCov で計測し、32.67% から 52.28% まで引き上げた。
環境は Rails 8.0.5 / Ruby 3.4.8 / PostgreSQL / Docker Compose / Devise。

---

## 1. RSpec の導入手順

### 1-1. Gemfile に追加

```ruby
group :development, :test do
  gem "rspec-rails"        # Rails用RSpec本体
  gem "factory_bot_rails"  # テストデータ作成
end
```

`capybara` と `selenium-webdriver` が `group :test` にあれば、システムスペックもそのまま書ける。

### 1-2. インストールとジェネレータ

Docker 環境なのでコンテナ内で実行する。

```bash
docker compose exec web bundle install
docker compose exec web bin/rails generate rspec:install
docker compose exec web bundle binstubs rspec-core   # bin/rspec を用意
```

生成されるもの:

| ファイル | 役割 |
|---|---|
| `.rspec` | RSpec の起動オプション（`--require spec_helper`） |
| `spec/spec_helper.rb` | RSpec 本体の設定 |
| `spec/rails_helper.rb` | Rails を読み込む設定。テストからはこちらを require する |

### 1-3. spec/rails_helper.rb の設定

生成された `RSpec.configure do |config|` ブロックの **中に** 追記する。
※ ブロックを新しく作って入れ子にすると二重定義になるので注意。

```ruby
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot のメソッドを create(:user) のように呼べる
  config.include FactoryBot::Syntax::Methods

  # Devise のログインヘルパー
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
end
```

`use_transactional_fixtures = true` は「テストが終わったら、そのテストが作ったデータを全部なかったことにする」設定。これがあるので、何度実行してもデータがぶつからない。

### 1-4. ジェネレータの既定を RSpec にする

`config/application.rb` の `class Application < Rails::Application` の中に書く。

```ruby
config.generators do |g|
  g.test_framework :rspec, fixture: false
end
```

これで `rails g model 〇〇` が `spec/` 側にファイルを作るようになる。

### 1-5. CI の変更

`.github/workflows/ci.yml` のテスト実行を書き換える。

```yaml
# 変更前（minitest）
run: bin/rails db:test:prepare test test:system

# 変更後（RSpec）
run: bin/rails db:test:prepare && bin/rspec
```

`test` と `test:system` は minitest 用の rake タスク。`bin/rspec` が RSpec の実行コマンド。

### 1-6. test/ の削除

RSpec に一本化するなら、Rails 標準の `test/` ディレクトリは削除する。
CI から minitest の実行を外した時点で、`test/` はどこからも実行されなくなる。

---

## 2. FactoryBot（テストデータの型）

### 2-1. ファクトリとは

「たい焼きの型」。`build(:user)` と一言お願いするだけで、型どおりのデータが出てくる。
毎回テストのたびに全項目を手で書く必要がなくなる。

### 2-2. 作り方

```bash
docker compose exec web bin/rails g factory_bot:model user   # ジェネレータ
# または
mkdir -p spec/factories && touch spec/factories/users.rb      # 手で
```

`touch spec/factories` ではディレクトリは作れない（空ファイルができてしまう）。
ディレクトリは `mkdir`、ファイルは `touch`。

### 2-3. 実際のファクトリ

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # 一意制約があるので sequence で毎回違う値にする
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "テストユーザー" }
    password { "password123" }   # Devise の :validatable が要求する
  end
end
```

```ruby
# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    user                       # belongs_to :user → 関連する user も自動生成される
    title { "猫のごはんについて" }
    content { "食欲がないのですが、どうすればいいでしょうか。" }
    category { Question::CATEGORIES.first }   # モデルの定数を参照すると壊れにくい
  end
end
```

```ruby
# spec/factories/likes.rb（ポリモーフィック関連）
FactoryBot.define do
  factory :like do
    user
    for_question   # デフォルトの likeable を決めておく

    trait :for_question do
      association :likeable, factory: :question
    end

    trait :for_answer do
      association :likeable, factory: :answer
    end
  end
end
```

使うときは `create(:like)` / `create(:like, :for_answer)`。

### 2-4. デフォルト値の上書き

```ruby
build(:user)                 # 型どおり（デフォルト値）
build(:user, username: "")   # username だけ空にする
```

ラーメン屋で「ラーメンください」と「ネギ抜きで」の関係。

### 2-5. 全ファクトリの健康診断

```bash
bin/rails runner "FactoryBot.lint(traits: true)"
```

全ファクトリと全 trait を実際に生成して、バリデーションを落とさないか確かめる。

### 2-6. ジェネレータの上書き事故に注意

`bin/rails g rspec:model answer` はスペックと**同時にファクトリも生成しようとする**。
既存のファクトリと衝突して「上書きしますか？」と聞かれ、非対話モードだと Yes 扱いで**既存のファクトリが空の雛形で潰される**。

```bash
bin/rails g rspec:model answer --skip   # 既存ファイルは触らない
```

また、ジェネレータに渡すのは**モデルのクラス名（単数形・拡張子なし）**。

```bash
bin/rails g rspec:model answer     # ⭕
bin/rails g rspec:model answers    # ❌ Answers という定数は無い
bin/rails g rspec:model likes.rb   # ❌ 複数形 + 拡張子
```

---

## 3. テストの基本構造

### 3-1. 3ステップ

```
① じゅんび  … 材料を用意する
② やってみる … 実際に動かす
③ たしかめる … 結果が正しいか見る
```

```ruby
RSpec.describe Question, type: :model do   # 何をテストするか
  describe "title" do                       # グループ分け（入れ子にできる）
    it "空だと無効になる" do                  # テスト1本＝it
      question = build(:question, title: "")  # ① じゅんび
      expect(question).to be_invalid          # ②③ やってみる・たしかめる
    end
  end
end
```

### 3-2. describe は「見出し」

`describe` の入れ子は、そのまま**目次**になる。

```bash
bin/rspec --format documentation
```

```
Answer
  questionがないと無効になる
  userがないと無効になる
  content
    空だと無効になる
    5000文字ちょうどなら有効になる
    5001文字だと無効になる
```

**目次を上から読んで日本語として意味が通るか**が、グループ分けが正しいかの判断基準になる。

- 「Answer の **content** は 空だと無効になる」⭕
- 「Answer の **content** は **question**がないと無効になる」❌ → content の話ではないので外に出す

`content` のルールは `validates :content, ...` に、`question` のルールは `belongs_to :question` に書いてある。
**モデルで書かれている場所が違うものは、テストでも別の引き出しに入れる。**

### 3-3. do と end はペア

```ruby
RSpec.describe Answer, type: :model do   ← 0マス
  describe "content" do                  ← 2マス
    it "空だと無効になる" do              ← 4マス
    end                                  ← 4マス（it と同じ深さ）
  end                                    ← 2マス（describe と同じ深さ）
end                                      ← 0マス
```

**`do` と `end` は必ず同じ字下げの深さ**になる。これが揃っていれば開け閉めが正しい。
`do` の数と `end` の数も必ず一致する。

---

## 4. build と create

| | やること | たとえ |
|---|---|---|
| `build` | 頭の中で作るだけ。DBには書かない | 「猫という名前にしよう」と考えているだけ |
| `create` | 本当にDBに書く | 名簿にペンで書き込んだ |

バリデーションの確認は保存不要なので `build` のほうが速い。

### create が必要になるケース

**uniqueness（重複チェック）のとき。** 「同じ名前の人がもういないか名簿を調べる」ので、
じゃまする側が本当にDBに書かれていないといけない。

```ruby
it "usernameが他の人とかぶっていると無効になる" do
  create(:user, username: "tama")              # ① 先に名簿に書く（create）
  duplicate = build(:user, username: "tama")   # ② 同じ名前で作ろうとする
  expect(duplicate).to be_invalid              # ③ ダメなはず
end
```

①だけ `create`、②は `build` のまま。

### 「同じ」と「別」の作り分け

`create(:user)` と書くたびに**新しい人が生まれる**。

```
create(:user) を2回よんだ  → user1（id:1）と user2（id:2）  ← 別人
1回だけよんで2回つかった   → user3（id:3）と user3（id:3）  ← 同じ人
```

**同じにしたいものは1回だけ作って変数に入れる。別にしたいものは2回作る。**

```ruby
# 同じ人・同じ質問（ダメなパターン）
user = create(:user)
question = create(:question)          # 質問は1つ

# 同じ人・別の質問（OKなパターン）
user = create(:user)
question1 = create(:question)         # 質問は2つ
question2 = create(:question)
```

---

## 5. マッチャ（確かめ方の種類）

| マッチャ | 意味 | 使う場面 |
|---|---|---|
| `be_valid` | 保存できる状態か | バリデーションが通ること |
| `be_invalid` | 保存できない状態か | バリデーションで弾かれること |
| `include(x)` | 中に x が入っているか | 検索結果にヒットすること |
| `not_to include(x)` | 中に x が入っていないか | 検索結果に混じらないこと |
| `match_array([...])` | 顔ぶれが完全一致するか（順不同） | 全件返ること |
| `be_empty` | 空っぽか | 0件になること |
| `eq("...")` | 値がぴったり同じか | 文字列や数値の答え合わせ |

`be_valid` / `be_invalid` は**マルバツ問題**、`eq` は**記述問題の答え合わせ**。

`eq` は失敗したとき、期待値と実際の値を並べて見せてくれる。

```
expected: "2026年7月21日 14:33"
     got: "2026年7月21日 05:33"
```

### include はセットで書く

```ruby
expect(Question.search("猫")).to include(hit)
expect(Question.search("猫")).not_to include(miss)
```

「入っている」だけだと、**検索が壊れて全件返すようになってもテストが通ってしまう**。
「余計なものが混じっていない」も確かめて、はじめて検索が正しいと言える。

---

## 6. バリデーションのテスト

### 6-1. 検証したい項目以外は正常にする

```ruby
build(:question, title: "")   # title だけ空、他はファクトリの正常値
```

これがバリデーションテストの鉄則。

### 6-2. 境界値は両側から挟む

```ruby
it "100文字ちょうどなら有効になる" do
  expect(build(:question, title: "あ" * 100)).to be_valid
end

it "101文字だと無効になる" do
  expect(build(:question, title: "あ" * 101)).to be_invalid
end
```

片方だけだとオフバイワンエラー（境界が1つずれている）を見逃す。

### 6-3. エラーメッセージまで検証する

```ruby
expect(question.errors[:title]).to include("を入力してください")
```

**別のバリデーションが原因で無効になっていないこと**を確かめるため。
title のテストなのに category の設定ミスで無効になっていたら、テストが通っても意味がない。

日本語のエラーメッセージ（rails-i18n）:

| バリデーション | メッセージ |
|---|---|
| `presence: true` | `を入力してください` |
| `length: { maximum: 100 }` | `は100文字以内で入力してください` |
| `inclusion: { in: [...] }` | `は一覧にありません` |

### 6-4. ファクトリのデフォルト値の確認は必ず最初に

```ruby
it "ファクトリのデフォルト値で有効になる" do
  expect(build(:user)).to be_valid
end
```

**体重計の0kg合わせ**にあたる。

もしファクトリが壊れていたら、「username が空だと無効」のテストも通ってしまう。
ただし理由が違う（username が空だからではなく、パスワードが無いから）。**テストが嘘をつく**状態になる。

これが緑なら「型は正常＝ここが出発点」と保証でき、以降のテストで無効になったのは
**自分がわざと壊した1か所のせい**だと言い切れる。

### 6-5. ルールが「ない」ことのテスト

```ruby
it "空でも有効になる" do
  user = build(:user, name: "")
  expect(user).to be_valid       # be_invalid ではない
end
```

`name` には `presence: true` が付いていない、という仕様も立派なテスト対象。

---

## 7. 特殊なケース

### 7-1. scope 付きの uniqueness

```ruby
validates :user_id, uniqueness: { scope: [ :likeable_type, :likeable_id ] }
```

「名前ひとつ」ではなく「**組み合わせ**でかぶってはダメ」という意味。

出席簿でたとえると:

| | たまさん | ぽちさん |
|---|---|---|
| **算数** | ✍️ サイン済み | ✍️ サインできる ⭕ |
| **国語** | ✍️ サインできる ⭕ | |

- たまさんが算数にもう一度 → ❌（同じ人・同じ対象）
- たまさんが国語に → ⭕（同じ人でも対象が違う）
- ぽちさんが算数に → ⭕（同じ対象でも人が違う）

**❌ のパターンだけでなく、⭕ のパターンもテストしないと `scope` の意味を確かめたことにならない。**

```ruby
describe "同じ対象へのいいねは1人1回まで" do
  it "同じユーザーが同じ質問に2回いいねすると無効になる" do
    user = create(:user)
    question = create(:question)
    create(:like, user: user, likeable: question)
    second = build(:like, user: user, likeable: question)
    expect(second).to be_invalid
  end

  it "別のユーザーなら同じ質問にいいねできる" do
    question = create(:question)
    create(:like, likeable: question)
    another = build(:like, likeable: question)
    expect(another).to be_valid
  end

  it "同じユーザーでも別の質問ならいいねできる" do
    user = create(:user)
    question1 = create(:question)
    question2 = create(:question)
    create(:like, user: user, likeable: question1)
    other = build(:like, user: user, likeable: question2)
    expect(other).to be_valid
  end
end
```

### 7-2. polymorphic 関連

```ruby
belongs_to :likeable, polymorphic: true
```

いいねは質問にも回答にも押せる＝相手が2種類ある。
**2つの箱**で相手を覚えている。

| | `likeable_type` | `likeable_id` |
|---|---|---|
| 質問へのいいね | `Question` | 107 |
| 回答へのいいね | `Answer` | 1 |

**宛名書き**と同じ。「建物名（type）」＋「部屋番号（id）」の2つそろって相手が決まる。

---

## 8. ヘルパーのテスト

### 8-1. 準備

```bash
bin/rails g rspec:helper application   # spec/helpers/application_helper_spec.rb
```

```ruby
RSpec.describe ApplicationHelper, type: :helper do
  describe "#posted_at" do
    it "..." do
      expect(helper.posted_at(time)).to eq("...")
    end
  end
end
```

ヘルパーはビューで使うものなので、テストでは `helper.` を付けて呼ぶ（決まり文句）。

### 8-2. 重複の集約

3か所のビューに同じ `strftime` がコピペされていたのを、ヘルパー1つにまとめた。

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def posted_at(time)
    time.strftime("%Y年%-m月%-d日 %H:%M")
  end
end
```

```erb
<%= posted_at(question.created_at) %>
```

書式を変えたいとき、直すのは1か所だけになる。

### 8-3. タイムゾーン（UTC と日本時間）

Rails は**DBにはUTC（世界共通の時計）で保存し、表示時に日本時間に直す**。
この「直す」役をしているのが `config.time_zone = "Tokyo"`。

```
DB（UTCで保存）  →  Rails が日本時間に直す  →  画面
   05:33                                       14:33
```

**注意：`Time.utc(...)` をそのままヘルパーに渡しても変換されない。**

```
① Time.utc(2026,7,21,5,33) を直接渡した    → 2026年7月21日 05:33（UTCのまま）
② いちどDBに入れて取り出してから渡した      → 2026年7月21日 14:33（日本時間）
```

本番では必ず `question.created_at`（DBから取り出した形）で使われるので、
テストも**DBを通す形**にしないと本番の状況を再現できない。

```ruby
it "UTCで保存された時刻が日本時間（+9時間）で表示される" do
  question = create(:question, created_at: Time.utc(2026, 7, 21, 5, 33))
  expect(helper.posted_at(question.created_at)).to eq("2026年7月21日 14:33")
end
```

### 8-4. strftime の書式

`%m` は「2桁で書く」。`-` を足すと「**ゼロで埋めない**」。

```
%-m月%-d日  →  5月3日
 %m月 %d日  →  05月03日
```

`"%Y年%-m月%-d日 %H:%M"` は月日にマイナスがあり、**時刻には無い**ので:

```
2026年5月3日 09:05
      ↑ ↑   ↑
   ゼロなし  ゼロあり
```

この `-` はたった1文字なので、消えても気づきにくい。だからテストで見張る。

```ruby
it "1桁の月日にゼロが付かない" do
  time = Time.zone.local(2026, 7, 5, 9, 5)
  expect(helper.posted_at(time)).to eq("2026年7月5日 09:05")
end
```

---

## 9. リクエストspec（コントローラのテスト）

### 9-1. モデルspecとの違い

| | モデルspec | リクエストspec |
|---|---|---|
| 調べるもの | データのルール | **画面の動き** |
| たとえ | 部品の検査 | **実際に走らせてみる** |
| 例 | 「空だと保存できない」 | 「一覧ページを開くと表示される」 |

車の工場で言えば、モデルspecが「エンジン単体の検査」なら、リクエストspecは「実際に走らせるテスト」。

### 9-2. 準備

```bash
bin/rails g rspec:request questions   # spec/requests/questions_spec.rb
```

```ruby
RSpec.describe "Questions", type: :request do
```

`type: :request` が目印。これが付いていると `get` や `post` でページを開ける。

### 9-3. 3つの命令

| 命令 | 意味 | ブラウザでの操作 |
|---|---|---|
| `get` | 見せて | URLを開く・リンクをクリック |
| `post` | 送ります | フォームの送信ボタン |
| `delete` | 消して | 削除ボタン |
| `patch` | 更新して | 編集フォームの送信 |

### 9-4. パスの単数形と複数形

**`s` が付くかどうか**で意味が変わる。

| 書き方 | URL | 用途 |
|---|---|---|
| `questions_path` | `/questions` | 一覧を見る・**新しく作る** |
| `question_path(question)` | `/questions/5` | **その質問1つ**を見る・消す |

新規作成のときはまだ番号が決まっていないので複数形。単数形は「どれか」を伝える必要があるのでカッコに渡す。

### 9-5. ログインの扱い

このアプリのコントローラには門番がいる。

```ruby
before_action :authenticate_user!
```

そのため、同じページでも結果が2通りに分かれる。

| 状況 | 結果 | 確認方法 |
|---|---|---|
| ログイン済み | 表示される（200） | `have_http_status(:ok)` |
| 未ログイン | ログイン画面へ追い返される（302） | `redirect_to(new_user_session_path)` |

ログインさせるのは1行。Devise の機能で、`spec/rails_helper.rb` に
`config.include Devise::Test::IntegrationHelpers, type: :request` を設定してあるので使える。

```ruby
sign_in user
```

**「追い返される」ほうも必ずテストする。** これを書いておかないと、
`before_action` の行が消えて誰でも見られる状態になっても気づけない。

### 9-6. ステータスコード

| 番号 | 名前 | 意味 |
|---|---|---|
| 200 | `:ok` | はい、どうぞ |
| 302 | （リダイレクト） | 別の場所へどうぞ |
| 422 | `:unprocessable_content` | **その内容では受け付けられません** |

422 は役所の窓口で「記入漏れがあるので受け付けられません」と書類を返されるイメージ。
追い返される（リダイレクト）のではなく、同じ窓口で書き直すのでフォーム画面が再表示される。

**注意：** `:unprocessable_entity` は Rack で非推奨になった。`:unprocessable_content` を使う。

### 9-7. 投稿のテスト（成功と失敗の両方）

コントローラの `create` には道が2つある。**両方テストしないと片方が未検証のまま残る。**

```ruby
if @question.save
  redirect_to questions_path      # 成功
else
  render :post, status: :unprocessable_entity   # 失敗
end
```

```ruby
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

      expect(Question.count).to eq(1)                   # ① 保存された
      expect(response).to redirect_to(questions_path)   # ② 一覧に戻った
    end
  end

  context "入力が正しくないとき" do
    it "質問が作成されない" do
      user = create(:user)
      sign_in user

      post questions_path, params: {
        question: { title: "", content: "食欲がないのですが", category: "食事" }
      }

      expect(Question.count).to eq(0)                              # 保存されていない
      expect(response).to have_http_status(:unprocessable_content) # フォームに戻った
    end
  end
end
```

**`params:` はフォームの入力欄そのもの。** ブラウザで各欄を埋めて送信ボタンを押した状態を表す。
`question:` という包みがあるのは、Rails のフォームが `question[title]` の形で送るため
（コントローラの `params.require(:question)` と対応している）。

投稿では **保存**と**画面遷移**の2つが起きるので、両方確かめて初めて「投稿できた」と言える。

### 9-8. 他人のデータを守るテスト

このアプリでは「自分の質問しか編集・削除できない」ようになっている。

```ruby
# app/controllers/questions_controller.rb
def set_own_question
  @question = current_user.questions.find_by(id: params[:id])
  redirect_to questions_path, alert: "自分の質問だけが編集・削除できます。" if @question.nil?
end
```

肝は `current_user.questions` の部分。

```ruby
Question.find_by(id: 5)                 # 全部の質問から探す（誰のでも見つかる）
current_user.questions.find_by(id: 5)   # 自分の質問からだけ探す ← こちら
```

**自分のロッカーの中だけを探している。** 他人の質問は入っていないので `nil` が返り、追い返される。

```ruby
describe "DELETE /questions/:id" do
  context "他人の質問を削除しようとしたとき" do
    it "削除されず、一覧にリダイレクトされる" do
      owner = create(:user)                        # 質問を書いた人
      question = create(:question, user: owner)    # その人の質問

      other = create(:user)                        # 別の誰か
      sign_in other                                # 別人としてログイン

      delete question_path(question)               # 消そうとする

      expect(Question.count).to eq(1)              # 消えていない ← ここが心臓部
      expect(response).to redirect_to(questions_path)
    end
  end
end
```

**なぜ2人必要なのか。** 1人だけだと「自分の質問を自分で消す」になり、消せて当たり前なのでテストにならない。
守りたいのは「他人のものを勝手に消されないこと」なので、**わざと別人を用意する**。

`user: owner` を書くのも大事。これがないとファクトリが勝手に別のユーザーを作り、
「誰の質問か」があいまいになる。

**一番大事なのは `expect(Question.count).to eq(1)`。**
リダイレクトされていても、裏でこっそり消えていたら意味がない。

もし誰かが `current_user.questions` を `Question` に書き換えてしまったら、
誰でも他人の質問を消せるアプリになる。画面上は普通に動くので人間の目では気づきにくい。
このテストがあれば、その瞬間に赤くなる。

### 9-9. カバレッジへの効果が大きい

リクエストspecは1本でカバレッジが大きく動く。ページを1回開くと関係するコードが全部通るため。

```
get questions_path
  → ルーティング → コントローラ → authenticate_user! → Question.search → ビュー
```

実績：モデルのテストを3本足しても 1.3% しか動かなかったが、
リクエストspec 7本で **33.98% → 52.28%** まで上がった。

---

## 10. よくあるエラーと対処

### 10-1. `end` の数が合わない

```
SyntaxError: Unmatched keyword, missing `end' ?
     3  RSpec.describe User, type: :model do
  >  8    describe "username" do
```

Ruby が**あやしい場所を指さしてくれる**。`>` の行を見る。
`do` の数と `end` の数を数える。字下げの深さで対応を確認する。

### 10-2. クォートの閉じ忘れ

```ruby
build(:user, username:")     # ❌ " が1個
build(:user, username: "")   # ⭕ " が2個
```

`"` を開いたまま閉じないと、Ruby は**そこから後ろを全部「文字列の中身」だと思い込む**。
だから `)` も飲み込まれ、「カッコが閉じていない」という**一見無関係なエラー**になる。

```
Unmatched `(', missing `)' ?
```

### 10-3. expect のないテストは緑になる

```ruby
it "何かのテスト" do
  # 準備だけして expect を書かなかった
end
```

RSpec は「**最後まで転ばずに走り終えたら合格**」と判断する。
何も確かめていないテストも緑になる。**テストで一番あぶない状態。**

### 10-4. テストDBが汚れている

```
ActiveRecord::RecordInvalid: ユーザー名はすでに存在します
```

`use_transactional_fixtures` が掃除してくれるのは**テストの中で作られたデータだけ**。
`rails runner` などテスト外で作ったデータは残り続ける。

```bash
docker compose exec web bin/rails db:test:prepare   # テストDBの掃除
```

変なエラーで落ちたとき、まずこれを試す。

### 10-5. モデルとスペックの置き場所を間違える

| ファイル | 役割 |
|---|---|
| `app/models/answer.rb` | アプリ本体（テストを受ける生徒） |
| `spec/models/answer_spec.rb` | テスト（問題用紙） |

テストコードをモデルファイルに書くと、アプリが起動しなくなる。

### 10-6. エラーは1つずつ順番に出てくる

Ruby は**文法のチェックが先**。構文エラーがあるうちは、その先のエラーは出てこない。
1つ直すと次が現れるのは、**進んでいる証拠**。

### 10-7. 打ち間違いによる `NoMethodError`

```
NoMethodError:
  undefined method 'content' for class RSpec::ExampleGroups::...
```

「**そんな名前のもの、知らないよ**」というエラー。`undefined method '◯◯'` の `◯◯` が
打ち間違えた名前。**このエラーが出たら、まず綴りを疑う。**

実際にやった間違い：

| 間違い | 正しい | 覚え方 |
|---|---|---|
| `content` | `context` | **`context` には `text` が入っている**（コン**テキスト**＝文脈） |
| `it` | `if` | `it` はテスト1本、`if` は条件分岐。`if` には `do 〜 end` が付かない |
| `radirect_to` | `redirect_to` | `re`（再び）+ `direct`（向ける） |

### 10-8. `{ }` の中のカンマ忘れ

```ruby
params: {
  question: {
    title: "",
    content: "食欲がないのですが"      # ← カンマが無い
    category: "食事"
  }
}
```

```
unexpected ':', expecting end-of-input
```

`{ }` の中は**リスト**。日本語の「りんご、みかん、ぶどう」の「、」と同じで、
**最後の項目以外はカンマが要る**。

カンマが無いと `"食欲がないのですが" category:` という意味不明なつながりになり、
「`:` が変なところにある」と怒られる。

### 10-9. rubocop が字下げを直してくれない

このプロジェクトは `rubocop-rails-omakase` を使っている。これは「細かいことは言わない」方針で、
**字下げの深さをチェックしない**。

```
1 file inspected, no offenses detected    ← ズレていてもこう出る
```

rubocop が見るのは行末の空白、ファイル末尾の改行、`do` の前のスペースなど。
**字下げのズレは手で直す**しかない。

VSCode なら範囲を選択して `Tab`（右へ1段）/ `Shift + Tab`（左へ1段）でまとめて動かせる。

---

## 11. テストが本物か確かめる方法

**わざとアプリを壊して、テストが赤くなるか見る。**

```bash
# 例1: Like の uniqueness をコメントアウト
# validates :user_id, uniqueness: { scope: [...] }

# 例2: タイムゾーン設定をコメントアウト
# config.time_zone = "Tokyo"
```

```
...F..              ← 6本中1本だけ赤くなった
.F.                 ← 3本中2本目だけ赤くなった
```

**1本だけ赤くなるのが良いテスト。** それぞれが自分の担当だけを見張っている証拠。
全部まとめて赤くなると、どこが壊れたのか特定できない。

確認したら `git checkout <ファイル>` で元に戻す。

---

## 12. 実際に見つけたバグ

`Question.search` が**二重定義**されていた。

```ruby
def self.search(keyword)
  ...
  where("... ILIKE :pattern ...", pattern: "%#{sanitize_sql_like(keyword)}%")   # 本物
end

def self.search(keyword)      # 2つ目
  ...
  where("... ILIKE :pattern ...", pattern: "%...%")                             # ニセモノ
end
```

Ruby は**同じ名前のメソッドが2つあると後に書いたほうが勝つ**ので、
アプリは下のニセモノを使っていた。実行されるSQLはこうなっていた:

```sql
WHERE (title ILIKE '%...%' OR content ILIKE '%...%')
```

「`...` という文字が入っている質問を探して」という意味になり、**検索窓が常に0件**を返す状態だった。
テストを書いたことで発覚した。

---

## 13. コマンド集

```bash
# テスト実行
docker compose exec web bin/rspec                                   # 全部
docker compose exec web bin/rspec spec/models/user_spec.rb          # 1ファイル
docker compose exec web bin/rspec --format documentation            # 目次つき

# テストDBの掃除
docker compose exec web bin/rails db:test:prepare

# ファクトリの健康診断
docker compose exec web bin/rails runner "FactoryBot.lint(traits: true)"

# スタイルチェック
docker compose exec web bin/rubocop spec          # 確認だけ
docker compose exec web bin/rubocop -a spec       # 自動修正

# ファイル生成
docker compose exec web bin/rails g rspec:model user
docker compose exec web bin/rails g rspec:helper application
docker compose exec web bin/rails g rspec:request questions
docker compose exec web bin/rails g factory_bot:model user

# カバレッジの赤い行を調べる（coverage/index.html をブラウザで開いてもよい）
docker compose exec web ruby -rjson -e '
data = JSON.parse(File.read("coverage/.resultset.json"))
cov = data.values.first["coverage"]
cov.each do |path, info|
  next unless path.include?("likeable")     # 調べたいファイル名
  lines = info.is_a?(Hash) ? info["lines"] : info
  src = File.readlines(path)
  lines.each_with_index do |hits, i|
    next if hits.nil?
    mark = hits.to_i.zero? ? "赤 未実行" : "緑 #{hits}回"
    puts "#{(i+1).to_s.rjust(2)}行 #{mark}  #{src[i].to_s.strip}"
  end
end'
```

---

## 14. 完成した構成

```
spec/
├── factories/
│   ├── answers.rb
│   ├── likes.rb
│   ├── questions.rb
│   └── users.rb
├── helpers/
│   └── application_helper_spec.rb    3本
├── models/
│   ├── answer_spec.rb                5本
│   ├── like_spec.rb                  6本
│   ├── question_spec.rb             21本
│   └── user_spec.rb                 14本
├── requests/
│   └── questions_spec.rb             7本
├── rails_helper.rb
└── spec_helper.rb
                                    計56本
```

カバレッジの推移：

| 時点 | テスト数 | カバレッジ |
|---|---|---|
| モデルspec完成 | 46本 | 32.67% |
| `liked_by?` 追加 | 49本 | 33.98% |
| リクエストspec（表示） | 53本 | 47.71% |
| リクエストspec（投稿・削除） | 56本 | **52.28%** |

`app/models/` `app/helpers/` は 100%。残っている穴は
`app/models/concerns/image_attachable.rb` の画像検証4行と、
answers / likes コントローラのリクエストspec。

---

## 15. 大事な考え方まとめ

1. **テストは「見張りロボット」** — 一度書けば何度でも一瞬で確かめてくれる
2. **テストが通る＝正しい、とは限らない** — 何も確かめていないテストも緑になる
3. **目次として意味が通るように `describe` を分ける** — モデルで書かれている場所が違うものは別の引き出しへ
4. **境界は両側から挟む** — 100文字OK・101文字NG のペアで書く
5. **「入っている」と「入っていない」をセットで** — 片方だけだと壊れても気づけない
6. **同じにしたいものは1回だけ作る。別にしたいものは2回作る**
7. **意味は人間が直し、見た目は機械（rubocop）が直す**
8. **わざと壊して、1本だけ赤くなるか確かめる**
9. **分岐は全部の道を通す** — `if` と `else` があるなら、成功したときと失敗したときの両方を書く
10. **「できる」だけでなく「できない」もテストする** — 未ログインなら弾かれる、他人のものは消せない。セキュリティはここで守る
11. **カバレッジは地図** — 数字だけ見ても分からないが、色を見れば「次に何をテストすべきか」が読み取れる
12. **打ち間違いはエラーの大半を占める** — `NoMethodError` が出たら、まず綴りを疑う
