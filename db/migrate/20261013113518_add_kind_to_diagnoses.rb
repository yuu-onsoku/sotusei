class AddKindToDiagnoses < ActiveRecord::Migration[8.0]
  def change
    # 簡易診断（5問・満点10点）か、詳細診断（13問・満点26点）か。
    # これが無いと、マイページで「20点 / 10点満点」のような表示になってしまう。
    # これまでに保存されたものはすべて簡易診断なので、既定値は "simple"。
    add_column :diagnoses, :kind, :string, default: "simple", null: false
  end
end
