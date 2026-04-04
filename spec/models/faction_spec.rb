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
require "rails_helper"

RSpec.describe Faction, type: :model do
  let!(:faction) { create :faction }

  describe 'associations' do
    it { should have_many(:doctrines) }
    it { should have_one(:restriction) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:const_name) }
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:side) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:const_name) }
  end
end
