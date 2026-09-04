# Rails 8 + RSpec 学習まとめ

猫コミュニティアプリ（卒業制作）に RSpec を導入し、モデルとヘルパーのテストを40本書くまでの記録。
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

## 9. よくあるエラーと対処

### 9-1. `end` の数が合わない

```
SyntaxError: Unmatched keyword, missing `end' ?
     3  RSpec.describe User, type: :model do
  >  8    describe "username" do
```

Ruby が**あやしい場所を指さしてくれる**。`>` の行を見る。
`do` の数と `end` の数を数える。字下げの深さで対応を確認する。

### 9-2. クォートの閉じ忘れ

```ruby
build(:user, username:")     # ❌ " が1個
build(:user, username: "")   # ⭕ " が2個
```

`"` を開いたまま閉じないと、Ruby は**そこから後ろを全部「文字列の中身」だと思い込む**。
だから `)` も飲み込まれ、「カッコが閉じていない」という**一見無関係なエラー**になる。

```
Unmatched `(', missing `)' ?
```

### 9-3. expect のないテストは緑になる

```ruby
it "何かのテスト" do
  # 準備だけして expect を書かなかった
end
```

RSpec は「**最後まで転ばずに走り終えたら合格**」と判断する。
何も確かめていないテストも緑になる。**テストで一番あぶない状態。**

### 9-4. テストDBが汚れている

```
ActiveRecord::RecordInvalid: ユーザー名はすでに存在します
```

`use_transactional_fixtures` が掃除してくれるのは**テストの中で作られたデータだけ**。
`rails runner` などテスト外で作ったデータは残り続ける。

```bash
docker compose exec web bin/rails db:test:prepare   # テストDBの掃除
```

変なエラーで落ちたとき、まずこれを試す。

### 9-5. モデルとスペックの置き場所を間違える

| ファイル | 役割 |
|---|---|
| `app/models/answer.rb` | アプリ本体（テストを受ける生徒） |
| `spec/models/answer_spec.rb` | テスト（問題用紙） |

テストコードをモデルファイルに書くと、アプリが起動しなくなる。

### 9-6. エラーは1つずつ順番に出てくる

Ruby は**文法のチェックが先**。構文エラーがあるうちは、その先のエラーは出てこない。
1つ直すと次が現れるのは、**進んでいる証拠**。

---

## 10. テストが本物か確かめる方法

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

## 11. 実際に見つけたバグ

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

## 12. コマンド集

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
docker compose exec web bin/rails g factory_bot:model user
```

---

## 13. 完成した構成

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
│   ├── question_spec.rb             18本
│   └── user_spec.rb                  8本
├── rails_helper.rb
└── spec_helper.rb
                                    計40本
```

---

## 14. 大事な考え方まとめ

1. **テストは「見張りロボット」** — 一度書けば何度でも一瞬で確かめてくれる
2. **テストが通る＝正しい、とは限らない** — 何も確かめていないテストも緑になる
3. **目次として意味が通るように `describe` を分ける** — モデルで書かれている場所が違うものは別の引き出しへ
4. **境界は両側から挟む** — 100文字OK・101文字NG のペアで書く
5. **「入っている」と「入っていない」をセットで** — 片方だけだと壊れても気づけない
6. **同じにしたいものは1回だけ作る。別にしたいものは2回作る**
7. **意味は人間が直し、見た目は機械（rubocop）が直す**
8. **わざと壊して、1本だけ赤くなるか確かめる**
