require "image_processing/vips"

# 投稿された画像を、保存する前に縮める係。
# スマートフォンで撮った写真はそのままだと数MBあり、利用者に縮小を求めるのは不親切なため。
class ImageResizer
  # 長辺をここまで縮める。にゃんスタの表示は最大600px幅なので、拡大して見ても足りる。
  MAX_EDGE = 1600

  # これより大きいファイルは縮める前にメモリを使い切るおそれがあるので、触らずに返す。
  # （モデル側の検証で弾かれる）
  MAX_BYTES = 20.megabytes

  # GIF は縮めない。アニメーションが1コマ目だけに潰れてしまうため。
  RESIZABLE_TYPES = %w[image/png image/jpeg image/webp].freeze

  class << self
    # 受け取ったものと同じ形（UploadedFile）で返すので、呼び出し側は今までどおり扱える。
    # 縮められない場合は、受け取ったものをそのまま返す。
    def call(uploaded)
      return uploaded unless resizable?(uploaded)

      tempfile = ImageProcessing::Vips
                   .source(uploaded.tempfile.path)
                   .resize_to_limit(MAX_EDGE, MAX_EDGE)   # 長辺がMAX_EDGEを超えるときだけ縮む
                   .saver(strip: true)                    # 撮影場所などの付帯情報を落とす
                   .call

      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: uploaded.original_filename,
        type: uploaded.content_type
      )
    rescue StandardError => e
      # 縮められなくても投稿はできたほうがよいので、元のファイルをそのまま返す
      Rails.logger.error("[ImageResizer] #{e.class}: #{e.message}")
      uploaded
    end

    # 配列で届く場合（にゃんスタの写真は最大4枚）
    def call_each(uploaded_files)
      Array(uploaded_files).map { |file| call(file) }
    end

    private

    def resizable?(uploaded)
      uploaded.respond_to?(:tempfile) &&
        uploaded.content_type.in?(RESIZABLE_TYPES) &&
        uploaded.size.positive? &&
        uploaded.size <= MAX_BYTES
    end
  end
end
