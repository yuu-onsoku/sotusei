class AddAnswersCountToUsers < ActiveRecord::Migration[8.0]
  def up
    # バッジは回答数で決まる。毎回 answers を数えると回答の数だけSQLが飛ぶ（N+1）ので、
    # ユーザー側に数を持たせておき、回答が増減したとき Rails に更新させる（counter_cache）。
    add_column :users, :answers_count, :integer, default: 0, null: false

    # すでに回答があるユーザーの分を数え直す。
    # これを忘れると、本番にいる既存ユーザーが全員0件扱いになる。
    #
    # モデル（User.reset_counters）は使わない。マイグレーションは
    # 何ヶ月後に走るか分からず、そのときモデルが今と同じ形とは限らないため。
    execute <<~SQL.squish
      UPDATE users
      SET answers_count = (
        SELECT COUNT(*) FROM answers WHERE answers.user_id = users.id
      )
    SQL
  end

  def down
    remove_column :users, :answers_count
  end
end
