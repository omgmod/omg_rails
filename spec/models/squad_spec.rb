# == Schema Information
#
# Table name: squads
#
#  id                                                                :bigint           not null, primary key
#  category_position(Position within the tab the squad is in)        :integer          not null
#  name(Squad's custom name)                                         :string
#  pop(Total pop of the squad including unit and all upgrades)       :decimal(, )
#  tab_category(Tab this squad is in)                                :string           not null
#  total_model_count(Total model count of the unit and all upgrades) :integer
#  uuid(Unique uuid)                                                 :string           not null
#  vet(Squad's veterancy)                                            :decimal(, )
#  created_at                                                        :datetime         not null
#  updated_at                                                        :datetime         not null
#  available_unit_id                                                 :bigint
#  company_id                                                        :bigint
#
# Indexes
#
#  index_squads_on_available_unit_id  (available_unit_id)
#  index_squads_on_company_id         (company_id)
#  index_squads_on_uuid               (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (available_unit_id => available_units.id)
#  fk_rails_...  (company_id => companies.id)
#
require "rails_helper"

RSpec.describe Squad, type: :model do
  let!(:squad) { create :squad }

  describe 'associations' do
    it { should belong_to(:company) }
    it { should belong_to(:available_unit) }
    it { should have_many(:squad_upgrades) }
    it { should have_many(:available_upgrades) }

    context "when transporting squads" do
      let!(:passenger1) { create :squad, ruleset: squad.company.ruleset }
      let!(:passenger2) { create :squad, ruleset: squad.company.ruleset }
      let!(:transported_squad1) { create :transported_squad, transport_squad: squad, embarked_squad: passenger1}
      let!(:transported_squad2) { create :transported_squad, transport_squad: squad, embarked_squad: passenger2}

      it "has the association" do
        expect(squad.reload.squads_in_transport).to match_array([passenger1, passenger2])
        expect(squad.transporting_transported_squads).to match_array([transported_squad1, transported_squad2])
        expect(passenger1.embarked_transported_squad).to eq transported_squad1
        expect(passenger2.embarked_transported_squad).to eq transported_squad2
        expect(passenger1.embarked_transport).to eq squad
        expect(passenger2.embarked_transport).to eq squad
      end

      it "destroys the transported_squads when the transport is deleted" do
        expect { squad.reload.destroy! }.to change { TransportedSquad.count }.by(-2).and change { Squad.count }.by(-1)
      end
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:company) }
    it { should validate_presence_of(:vet) }
    it { should validate_presence_of(:tab_category) }
    it { should validate_presence_of(:category_position) }
    it { should validate_numericality_of(:vet) }
    it { should validate_numericality_of(:category_position) }
  end
end
