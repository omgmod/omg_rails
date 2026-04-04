# == Schema Information
#
# Table name: factions
#
#  id                                                           :bigint           not null, primary key
#  const_name(Faction CONST name for battlefile)                :string           not null
#  display_name(Display name)                                   :string           not null
#  internal_name(Name for internal code use, may not be needed) :string           not null
#  name(Raw name)                                               :string           not null
#  race(In-game race id)                                        :integer
#  side(Allied or Axis side)                                    :string           not null
#  created_at                                                   :datetime         not null
#  updated_at                                                   :datetime         not null
#
# Indexes
#
#  index_factions_on_const_name  (const_name) UNIQUE
#  index_factions_on_name        (name) UNIQUE
#
class Faction < ApplicationRecord
  has_many :doctrines, inverse_of: :faction
  has_one :restriction

  enum side: {
    allied: "allied",
    axis: "axis"
  }

  validates_presence_of :name
  validates_presence_of :const_name
  validates_presence_of :display_name
  validates_presence_of :side
  validates_uniqueness_of :name
  validates_uniqueness_of :const_name

  def side_integer
    if side == Faction.sides[:allied]
      0
    else
      1
    end
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :display_name, as: :displayName
    expose :internal_name, as: :internalName
    expose :side
  end
end
