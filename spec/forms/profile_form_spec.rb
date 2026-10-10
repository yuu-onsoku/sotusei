require 'rails_helper'

# ProfileForm を入れた目的は、コントローラを短くすることだけではない。
# 「検証を通ってからアイコンを消す」という順番を守らせることが本題なので、そこを確かめる。
RSpec.describe ProfileForm do
  def image_file
    fixture_file_upload("spec/fixtures/files/test_image.png", "image/png")
  end

  let(:user) { create(:user) }

  it "ユーザー名とお名前を変えられる" do
    form = ProfileForm.new(user: user, username: "あたらしい名前", name: "ねこ太郎")

    expect(form.save).to be true
    expect(user.reload.username).to eq("あたらしい名前")
    expect(user.name).to eq("ねこ太郎")
  end

  # 以前のコントローラは update の前に purge していたため、
  # 保存に失敗してもアイコンだけ消えてしまっていた
  it "ユーザー名が空なら、アイコンを外す指示があっても外さない" do
    user.avatar.attach(image_file)

    form = ProfileForm.new(user: user, username: "", remove_avatar: "1")

    expect(form.save).to be false
    expect(user.reload.avatar).to be_attached
  end

  it "外す指示と新しい画像が同時に来たら、外す方を優先する" do
    user.avatar.attach(image_file)

    form = ProfileForm.new(user: user, username: user.username,
                           avatar: image_file, remove_avatar: "1")

    expect(form.save).to be true
    expect(user.reload.avatar).not_to be_attached
  end

  it "届かなかった項目は書き換えない" do
    user.update!(name: "もとの名前")

    # name を渡さない。元の update は送られたキーだけ書き換えていたので、そこを守る
    form = ProfileForm.new(user: user, username: "名前だけ変える")

    expect(form.save).to be true
    expect(user.reload.name).to eq("もとの名前")
  end
end
