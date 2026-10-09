Kaminari.configure do |config|
  # 1ページあたりの件数。一覧ごとに page(n).per(件数) で上書きできる。
  # にゃんスタは3列の格子なので、12件だとちょうど4段になる。
  config.default_per_page = 12

  # ページ送りに出す数字の数。出しすぎるとスマホで横にはみ出すため少なめにする。
  config.window = 1          # 現在のページの前後1つずつ
  config.outer_window = 1    # 最初と最後のページ
end
