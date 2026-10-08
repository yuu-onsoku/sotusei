require 'rails_helper'

RSpec.describe "Places", type: :request do
  # Google に実際に問い合わせないよう、検索の係を差し替える
  let(:vet) do
    PlaceSearch::Place.new(
      id: "v1", name: "ねこ動物病院", address: "愛知県名古屋市中区1-1",
      rating: 4.5, rating_count: 120, maps_url: "https://maps.google.com/?cid=1",
      lat: 35.17, lng: 136.88
    )
  end

  let(:hotel) do
    PlaceSearch::Place.new(
      id: "h1", name: "ねこホテル", address: "愛知県名古屋市中村区2-2",
      rating: 4.0, rating_count: 30, maps_url: "https://maps.google.com/?cid=2",
      lat: 35.17, lng: 136.88
    )
  end

  # 飼う前の下調べにも使うため、ログイン不要であることが大事
  it "ログインしていなくても開ける" do
    get places_path
    expect(response).to have_http_status(:ok)
  end

  it "最初は案内だけが出る" do
    get places_path

    expect(response.body).to include("住所や駅名を入れるか")
  end

  describe "住所でさがす" do
    it "見つかると一覧が出る" do
      allow(PlaceSearch).to receive(:geocode).with("名古屋駅").and_return([ 35.17, 136.88 ])
      allow(PlaceSearch).to receive(:veterinaries).and_return([ vet ])
      allow(PlaceSearch).to receive(:pet_hotels).and_return([ hotel ])

      get places_path(q: "名古屋駅")

      expect(response.body).to include("ねこ動物病院")
      expect(response.body).to include("ねこホテル")
      expect(response.body).to include("愛知県名古屋市中区1-1")
    end

    it "見つからないと案内が出て、落ちない" do
      allow(PlaceSearch).to receive(:geocode).and_return(nil)

      get places_path(q: "ぞぞぞぞぞ")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("見つかりませんでした")
    end
  end

  describe "現在地でさがす" do
    # 現在地が来ているときは、住所を調べ直さずそのまま使う
    it "緯度経度をそのまま使う" do
      expect(PlaceSearch).not_to receive(:geocode)
      allow(PlaceSearch).to receive(:veterinaries).and_return([ vet ])
      allow(PlaceSearch).to receive(:pet_hotels).and_return([])

      get places_path(lat: "35.17", lng: "136.88")

      expect(response.body).to include("ねこ動物病院")
    end
  end

  # 外部サービスが落ちていても、画面が壊れないこと
  it "検索に失敗しても画面は出る" do
    allow(PlaceSearch).to receive(:geocode).and_return([ 35.17, 136.88 ])
    allow(PlaceSearch).to receive(:veterinaries).and_return([])
    allow(PlaceSearch).to receive(:pet_hotels).and_return([])

    get places_path(q: "名古屋駅")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("近くに動物病院が見つかりませんでした")
  end
  # 作っても辿り着けなければ使われない。導線をここで固定する。
  describe "導線" do
    it "未ログインのトップから行ける" do
      get root_path
      expect(response.body).to include(places_path)
    end

    it "診断の結果から行ける" do
      post diagnoses_path, params: { answers: { "0" => "0", "1" => "0", "2" => "0", "3" => "0", "4" => "0" } }
      get result_diagnoses_path

      expect(response.body).to include(places_path)
    end

    it "覚悟のチェックリストの結果から行ける" do
      sign_in create(:user)
      post checklists_path
      get result_checklists_path

      expect(response.body).to include(places_path)
    end
  end
end
