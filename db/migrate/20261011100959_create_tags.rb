class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false

      t.timestamps
    end

    # 同じ名前のタグを2つ作らない。アプリ側の find_or_create_by だけでは、
    # 2人が同時に同じタグを付けたときに両方作られてしまうため、DBでも止める
    add_index :tags, :name, unique: true
  end
end
