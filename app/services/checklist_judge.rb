# app/services/checklist_judge.rb
class ChecklistJudge
  # チェック項目（起動時に1度だけ読み込む）
  ITEMS = YAML.load_file(Rails.root.join("config/checklist_items.yml"))["items"].freeze

  def self.items
    ITEMS
  end

  # checked は ✅ が付いた項目の番号の配列
  # => ["0", "3", "5"]
  def initialize(checked)
    @checked = checked
  end

  # ✅ が付いていない項目を返す
  def unchecked_items
    self.class.items.reject.with_index do |_item, index|
      @checked.include?(index.to_s)
    end
  end

  # 全部で何項目あるか
  def total_count
    self.class.items.size
  end

  # ✅ が付いた項目の数（全体 − まだの数）
  def checked_count
    total_count - unchecked_items.size
  end

  # 全部に ✅ が付いたか
  def all_checked?
    unchecked_items.empty?
  end
end
