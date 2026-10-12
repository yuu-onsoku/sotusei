class AddOmniauthToUsers < ActiveRecord::Migration[8.0]
  def change
    # どのサービスの、どのアカウントか。
    # Google 側の uid は、その人のメールアドレスが変わっても変わらない識別子なので、
    # メールアドレスではなくこれで本人を特定する
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    # 同じ Google アカウントが2人のユーザーに紐づかないようにする。
    # パスワード登録だけの人は両方 NULL になるが、PostgreSQL は
    # NULL を「互いに違う値」として扱うので、unique でも何人でも入る
    add_index :users, [ :provider, :uid ], unique: true
  end
end
