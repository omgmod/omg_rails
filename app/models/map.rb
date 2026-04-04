# == Schema Information
#
# Table name: maps
#
#  id                                               :bigint           not null, primary key
#  category(Map category: meme or competitive)      :string           default("competitive"), not null
#  enabled(Whether this map is in the rotation)     :boolean          default(TRUE), not null
#  name(Map name from CDN manifest (e.g. 4p_Arras)) :string           not null
#  created_at                                       :datetime         not null
#  updated_at                                       :datetime         not null
#
# Indexes
#
#  index_maps_on_category  (category)
#  index_maps_on_enabled   (enabled)
#  index_maps_on_name      (name) UNIQUE
#
class Map < ApplicationRecord
  enum category: { meme: "meme", competitive: "competitive" }

  has_many :map_vetoes, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true

  scope :enabled, -> { where(enabled: true) }

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :category
    expose :enabled
  end
end
