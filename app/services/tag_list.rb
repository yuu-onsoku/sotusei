# 画面から届く「三毛猫, 子猫, 寝顔」のような1行の文字列を、タグ名の配列に変換する係。
#
# JavaScript を増やさずに済ませたいので、入力はテキスト欄1つ。
# そのぶん「人がどう打ってくるか分からない」をここで引き受ける。
class TagList
  # 区切りは半角カンマ・全角カンマ・読点のどれでもよい（人によって打ち方が違う）
  SEPARATOR = /[,、，]/
  MAX_LENGTH = 20

  # 例: " 三毛猫, #子猫 ,, 子猫 " → ["三毛猫", "子猫"]
  def self.parse(value)
    return [] if value.blank?

    value.to_s
         .split(SEPARATOR)
         .map { |name| normalize(name) }
         .reject(&:blank?)
         .uniq
  end

  # 前後の空白と、先頭の # を取る
  def self.normalize(name)
    # Ruby の strip は全角スペース（U+3000）を取らないので [[:space:]] を使う。
    # # を取ったあとにもう一度空白を取る（"# 子猫" のような打ち方があるため）
    name.to_s
        .gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
        .delete_prefix("#")
        .delete_prefix("＃")
        .gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
  end
end
