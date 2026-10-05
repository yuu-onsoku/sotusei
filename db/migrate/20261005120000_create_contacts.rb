class CreateContacts < ActiveRecord::Migration[8.0]
  # お問い合わせ。ログインしていない人も送れるようにするため user への参照は持たない。
  # email は返信先なので必須。name は任意。
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
