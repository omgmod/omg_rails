module OMG
  class MapVetoes < Grape::API
    resource :maps do
      desc "Get all enabled maps"
      get do
        present Map.enabled.order(:category, :name), using: Map::Entity
      end
    end

    resource :map_vetoes do
      before do
        authenticate!
      end

      desc "Get vetoes for a company"
      params do
        requires :companyId, type: Integer, desc: "Company id"
      end
      get do
        company = Company.find(declared_params[:companyId])
        error!("Not your company", 403) unless company.player_id == current_player.id

        present company.vetoed_maps, using: Map::Entity
      end

      desc "Add a map veto for a company"
      params do
        requires :companyId, type: Integer, desc: "Company id"
        requires :mapId, type: Integer, desc: "Map id to veto"
      end
      post do
        company = Company.find(declared_params[:companyId])
        error!("Not your company", 403) unless company.player_id == current_player.id

        map = Map.find(declared_params[:mapId])
        veto = MapVeto.new(company: company, map: map)

        if veto.save
          present company.vetoed_maps.reload, using: Map::Entity
        else
          error!(veto.errors.full_messages.join(", "), 422)
        end
      end

      desc "Remove a map veto for a company"
      params do
        requires :companyId, type: Integer, desc: "Company id"
        requires :mapId, type: Integer, desc: "Map id to remove veto for"
      end
      delete do
        company = Company.find(declared_params[:companyId])
        error!("Not your company", 403) unless company.player_id == current_player.id

        veto = company.map_vetoes.find_by!(map_id: declared_params[:mapId])
        veto.destroy!

        present company.vetoed_maps.reload, using: Map::Entity
      end
    end
  end
end
