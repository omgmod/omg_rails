module Admin
  class MapsController < AdminController
    before_action :set_map, only: [:update]

    def index
      @maps = Map.order(:category, :name)
      @competitive_maps = @maps.competitive
      @meme_maps = @maps.meme
    end

    def update
      if @map.update(map_params)
        redirect_to admin_maps_path, notice: "Map was successfully updated."
      else
        redirect_to admin_maps_path, alert: @map.errors.full_messages.to_sentence
      end
    end

    def sync
      result = MapSyncService.new.sync
      redirect_to admin_maps_path, notice: "Synced #{result[:total]} maps from CDN (#{result[:created]} new)."
    rescue => e
      redirect_to admin_maps_path, alert: "Failed to sync maps: #{e.message}"
    end

    private

    def set_map
      @map = Map.find(params[:id])
    end

    def map_params
      params.require(:map).permit(:category, :enabled)
    end
  end
end
