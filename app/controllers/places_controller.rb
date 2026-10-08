class PlacesController < ApplicationController
  # 飼う前の下調べにも使えるよう、ログイン不要にする

  def index
    @query = params[:q].to_s.strip
    @lat = params[:lat].presence
    @lng = params[:lng].presence

    # 現在地（lat/lng）が来ていればそれを優先し、無ければ入力された場所を調べる
    if @lat && @lng
      @center = [ @lat.to_f, @lng.to_f ]
    elsif @query.present?
      @center = PlaceSearch.geocode(@query)
      @not_found = @center.nil?
    end

    return if @center.blank?

    @veterinaries = PlaceSearch.veterinaries(lat: @center[0], lng: @center[1])
    @pet_hotels = PlaceSearch.pet_hotels(lat: @center[0], lng: @center[1])
  end
end
