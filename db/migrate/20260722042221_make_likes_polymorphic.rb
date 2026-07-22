class MakeLikesPolymorphic < ActiveRecord::Migration[8.0]
  # 質問だけでなく回答にもいいねできるよう、likes を polymorphic に付け替える
  def up
    add_reference :likes, :likeable, polymorphic: true

    # 既存のいいねはすべて質問へのもの
    execute "UPDATE likes SET likeable_type = 'Question', likeable_id = question_id"

    change_column_null :likes, :likeable_type, false
    change_column_null :likes, :likeable_id, false

    # question_id を消すと index_likes_on_user_id_and_question_id も一緒に消える
    remove_reference :likes, :question, foreign_key: true

    # 1ユーザーにつき1対象1いいねまで
    add_index :likes, [ :user_id, :likeable_type, :likeable_id ],
              unique: true, name: "index_likes_on_user_and_likeable"
  end

  def down
    add_reference :likes, :question, foreign_key: true

    execute "DELETE FROM likes WHERE likeable_type <> 'Question'"
    execute "UPDATE likes SET question_id = likeable_id"

    change_column_null :likes, :question_id, false
    add_index :likes, [ :user_id, :question_id ], unique: true

    remove_index :likes, name: "index_likes_on_user_and_likeable"
    remove_reference :likes, :likeable, polymorphic: true
  end
end
