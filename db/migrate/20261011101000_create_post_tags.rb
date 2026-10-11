class CreatePostTags < ActiveRecord::Migration[8.0]
  def change
    # 投稿とタグをつなぐ中間テーブル。
    # いいね・コメント・ブックマークは polymorphic にしたが、タグはにゃんスタだけで
    # 使うので素直な2本の外部キーにした（質問にも付けたくなったらそのとき直す）
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    # 同じ投稿に同じタグを2回付けない
    add_index :post_tags, [ :post_id, :tag_id ], unique: true
  end
end
