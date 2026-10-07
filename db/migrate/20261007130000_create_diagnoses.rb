class CreateDiagnoses < ActiveRecord::Migration[8.0]
  # お迎え診断の結果。ログイン中に診断したときだけ残す。
  # answers に回答そのものを持たせ、あとから詳細を出し直せるようにする。
  # score と result は answers から計算できるが、一覧のたびに計算し直さないよう保存する。
  def change
    create_table :diagnoses do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :answers, null: false, default: {}
      t.integer :score, null: false
      t.string :result, null: false

      t.timestamps
    end

    # マイページで「自分のものを新しい順に」出すため
    add_index :diagnoses, [ :user_id, :created_at ]
  end
end
