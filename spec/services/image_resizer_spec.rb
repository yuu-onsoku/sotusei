require 'rails_helper'

RSpec.describe ImageResizer do
  # 送信されたファイルと同じ形のものを作る
  def uploaded(path, type)
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path), filename: File.basename(path), type: type
    )
  end

  # 指定した大きさの画像を一時ファイルとして作る
  def make_image(width, height, ext: "png")
    path = Rails.root.join("tmp", "resizer_test_#{width}x#{height}.#{ext}")
    Vips::Image.black(width, height).add(128).cast("uchar").write_to_file(path.to_s)
    path.to_s
  end

  describe ".call" do
    it "長辺が1600pxを超える画像は縮む" do
      file = uploaded(make_image(4000, 3000), "image/png")

      result = described_class.call(file)
      image = Vips::Image.new_from_file(result.tempfile.path)

      expect(image.width).to eq(1600)
      expect(image.height).to eq(1200)
    end

    it "縦長でも長辺が1600pxになる" do
      file = uploaded(make_image(1000, 4000), "image/png")

      result = described_class.call(file)
      image = Vips::Image.new_from_file(result.tempfile.path)

      expect([ image.width, image.height ].max).to eq(1600)
    end

    it "もともと小さい画像は縮まない" do
      file = uploaded(make_image(800, 600), "image/png")

      result = described_class.call(file)
      image = Vips::Image.new_from_file(result.tempfile.path)

      expect(image.width).to eq(800)
      expect(image.height).to eq(600)
    end

    # アニメーションが1コマ目に潰れるのを避けるため、GIFは縮めない
    it "GIFはそのまま返す" do
      file = uploaded(make_image(4000, 3000, ext: "gif"), "image/gif")

      expect(described_class.call(file)).to equal(file)
    end

    it "画像でないファイルはそのまま返す" do
      file = uploaded(Rails.root.join("spec/fixtures/files/not_image.txt").to_s, "text/plain")

      expect(described_class.call(file)).to equal(file)
    end

    # 縮める前にメモリを使い切らないよう、大きすぎるものは触らない（検証で弾かれる）
    it "20MBを超えるものはそのまま返す" do
      file = uploaded(make_image(800, 600), "image/png")
      allow(file).to receive(:size).and_return(21.megabytes)

      expect(described_class.call(file)).to equal(file)
    end

    # 縮められなくても投稿自体は通ってほしい
    it "縮小に失敗しても元のファイルを返す" do
      file = uploaded(make_image(4000, 3000), "image/png")
      allow(ImageProcessing::Vips).to receive(:source).and_raise(StandardError, "こわれた")

      expect(described_class.call(file)).to equal(file)
    end
  end

  describe ".call_each" do
    it "複数枚まとめて縮める" do
      files = [ uploaded(make_image(4000, 3000), "image/png"), uploaded(make_image(3000, 4000), "image/png") ]

      results = described_class.call_each(files)

      results.each do |result|
        image = Vips::Image.new_from_file(result.tempfile.path)
        expect([ image.width, image.height ].max).to eq(1600)
      end
    end
  end
end
