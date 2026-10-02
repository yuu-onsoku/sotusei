class CreateComments < ActiveRecord::Migration[8.0]
  # 質問にも回答にもコメントできるよう、最初から polymorphic で作る
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
