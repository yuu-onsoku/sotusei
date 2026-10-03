class CreatePosts < ActiveRecord::Migration[8.0]
  # にゃんスタの投稿。写真は Active Storage に持たせるのでカラムは持たない。
  # content（キャプション）は任意なので null を許す。
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
