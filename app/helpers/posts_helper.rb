module PostsHelper
  # にゃんスタの写真は、インスタと同じ3つの形のどれかに寄せて表示する。
  #   正方形 1080 x 1080（比 1.00）
  #   縦長   1080 x 1350（比 0.80）
  #   横長   1200 x  675（比 1.78）
  # 元の写真がどれに一番近いかで決める。
  ASPECTS = {
    "aspect-[4/5]" => 0.80,
    "aspect-square" => 1.00,
    "aspect-[16/9]" => 1.78
  }.freeze

  def post_aspect_class(image)
    width = image.blob.metadata["width"]
    height = image.blob.metadata["height"]

    # 解析がまだ済んでいない写真は正方形にしておく
    return "aspect-square" if width.blank? || height.blank? || height.to_i.zero?

    ratio = width.to_f / height

    # 3つの比のうち、一番ずれが小さいものをえらぶ
    ASPECTS.min_by { |_klass, target| (ratio - target).abs }.first
  end
end
