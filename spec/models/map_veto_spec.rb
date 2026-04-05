require "rails_helper"

RSpec.describe MapVeto, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:map) }
  end

  describe "validations" do
    subject { create :map_veto }

    it { should validate_uniqueness_of(:map_id).scoped_to(:company_id) }
  end

  describe "#competitive_veto_limit" do
    let(:company) { create :company }
    let(:competitive_4p_map1) { create :map, name: "4p_Arras", category: "competitive" }
    let(:competitive_4p_map2) { create :map, name: "4p_Langres", category: "competitive" }
    let(:competitive_2p_map) { create :map, name: "2p_Duel", category: "competitive" }
    let(:meme_map1) { create :map, name: "4p_MemeMap1", category: "meme" }
    let(:meme_map2) { create :map, name: "4p_MemeMap2", category: "meme" }

    it "allows vetoing one competitive map" do
      veto = MapVeto.new(company: company, map: competitive_4p_map1)
      expect(veto).to be_valid
    end

    it "prevents vetoing a second competitive map of the same size" do
      create :map_veto, company: company, map: competitive_4p_map1
      veto = MapVeto.new(company: company, map: competitive_4p_map2)
      expect(veto).not_to be_valid
      expect(veto.errors[:base]).to include("Company can only veto one competitive map per size")
    end

    it "allows vetoing competitive maps of different sizes" do
      create :map_veto, company: company, map: competitive_4p_map1
      veto = MapVeto.new(company: company, map: competitive_2p_map)
      expect(veto).to be_valid
    end

    it "allows vetoing multiple meme maps" do
      create :map_veto, company: company, map: meme_map1
      veto = MapVeto.new(company: company, map: meme_map2)
      expect(veto).to be_valid
    end

    it "allows vetoing a meme map alongside a competitive map of the same size" do
      create :map_veto, company: company, map: competitive_4p_map1
      veto = MapVeto.new(company: company, map: meme_map1)
      expect(veto).to be_valid
    end
  end
end