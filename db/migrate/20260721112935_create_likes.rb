class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true

      t.timestamps
    end

    # 1ユーザーにつき1投稿1いいねまで（DB側でも重複を防ぐ）
    add_index :likes, [ :user_id, :question_id ], unique: true
  end
end
