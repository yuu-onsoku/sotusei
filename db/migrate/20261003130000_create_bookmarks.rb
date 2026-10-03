class CreateBookmarks < ActiveRecord::Migration[8.0]
  # ブックマーク。いいねと同じく polymorphic で、今はにゃんスタの投稿に付ける。
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bookmarkable, polymorphic: true, null: false

      t.timestamps
    end

    # 1ユーザーにつき1対象1ブックマークまで（二重送信されても増えない）
    add_index :bookmarks, [ :user_id, :bookmarkable_type, :bookmarkable_id ],
              unique: true, name: "index_bookmarks_on_user_and_bookmarkable"
  end
end
