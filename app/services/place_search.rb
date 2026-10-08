require "net/http"
require "json"
require "uri"

# Google Maps Platform に問い合わせて、近くの動物病院・ペットホテルを探す係。
# APIキーはサーバー側だけで使い、画面には出さない。
class PlaceSearch
  GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json".freeze
  NEARBY_URL = "https://places.googleapis.com/v1/places:searchNearby".freeze
  TEXT_URL = "https://places.googleapis.com/v1/places:searchText".freeze

  # 受け取りたい項目だけを指定する。指定しないと料金の高い全項目が返るため必須。
  FIELDS = "places.id,places.displayName,places.formattedAddress,places.rating," \
           "places.userRatingCount,places.googleMapsUri,places.location".freeze

  DEFAULT_RADIUS = 5000      # 5km
  MAX_RESULTS = 10
  TIMEOUT = 5                # 秒。外部サービスの遅れで画面を止めないため

  Place = Struct.new(:id, :name, :address, :rating, :rating_count, :maps_url, :lat, :lng, keyword_init: true)

  class << self
    # 住所や駅名を緯度経度に変える。見つからなければ nil。
    def geocode(address)
      return nil if address.blank?

      uri = URI(GEOCODE_URL)
      uri.query = URI.encode_www_form(
        address: address, language: "ja", region: "jp", key: server_key
      )

      body = get_json(uri)
      return nil unless body && body["status"] == "OK"

      location = body.dig("results", 0, "geometry", "location")
      [ location["lat"], location["lng"] ]
    end

    # 近くの動物病院。Places の種別で絞れる。
    def veterinaries(lat:, lng:)
      nearby(lat: lat, lng: lng, types: [ "veterinary_care" ])
    end

    # ペットホテルは Places の種別に無いので、言葉で探す。
    def pet_hotels(lat:, lng:)
      text_search(query: "ペットホテル", lat: lat, lng: lng)
    end

    private

    def server_key
      ENV.fetch("GOOGLE_MAPS_SERVER_KEY")
    end

    def nearby(lat:, lng:, types:)
      body = post_json(NEARBY_URL, {
        includedTypes: types,
        maxResultCount: MAX_RESULTS,
        languageCode: "ja",
        locationRestriction: {
          circle: { center: { latitude: lat, longitude: lng }, radius: DEFAULT_RADIUS.to_f }
        }
      })

      to_places(body)
    end

    def text_search(query:, lat:, lng:)
      body = post_json(TEXT_URL, {
        textQuery: query,
        maxResultCount: MAX_RESULTS,
        languageCode: "ja",
        locationBias: {
          circle: { center: { latitude: lat, longitude: lng }, radius: DEFAULT_RADIUS.to_f }
        }
      })

      to_places(body)
    end

    def to_places(body)
      return [] if body.blank?

      (body["places"] || []).map do |place|
        Place.new(
          id: place["id"],
          name: place.dig("displayName", "text"),
          address: place["formattedAddress"].to_s.delete_prefix("日本、"),
          rating: place["rating"],
          rating_count: place["userRatingCount"],
          maps_url: place["googleMapsUri"],
          lat: place.dig("location", "latitude"),
          lng: place.dig("location", "longitude")
        )
      end
    end

    # 外部サービスが落ちていても画面が壊れないよう、失敗は nil / [] にして返す。
    def get_json(uri)
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      Rails.logger.error("[PlaceSearch] #{e.class}: #{e.message}")
      nil
    end

    def post_json(url, payload)
      uri = URI(url)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["X-Goog-Api-Key"] = server_key
      req["X-Goog-FieldMask"] = FIELDS
      req.body = payload.to_json

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.request(req)
      end
      return JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)

      Rails.logger.error("[PlaceSearch] HTTP #{res.code}: #{res.body}")
      nil
    rescue StandardError => e
      Rails.logger.error("[PlaceSearch] #{e.class}: #{e.message}")
      nil
    end
  end
end
