require "rails_helper"

RSpec.describe MapSelectionService do
  let(:ruleset) { create :ruleset }
  let(:battle) { create :battle, :open, ruleset: ruleset, size: 2 }
  let!(:player1) { create :player }
  let!(:player2) { create :player }
  let!(:company1) { create :company, player: player1, ruleset: ruleset }
  let!(:company2) { create :company, player: player2, ruleset: ruleset }
  let!(:bp1) { create :battle_player, battle: battle, player: player1, company: company1, side: "allied" }
  let!(:bp2) { create :battle_player, battle: battle, player: player2, company: company2, side: "axis" }

  subject { described_class.new(battle).select_map }

  describe "#select_map" do
    context "when there are maps matching the battle size" do
      let!(:matching_map) { create :map, name: "4p_Arras", enabled: true }
      let!(:wrong_size_map) { create :map, name: "2p_SmallMap", enabled: true }

      it "selects a map matching the battle total_size" do
        subject
        expect(battle.reload.map).to eq("4p_Arras")
      end

      it "does not select a map for a different size" do
        subject
        expect(battle.reload.map).not_to eq("2p_SmallMap")
      end
    end

    context "when a matching map is vetoed" do
      let!(:map1) { create :map, name: "4p_Arras", enabled: true }
      let!(:map2) { create :map, name: "4p_Langres", enabled: true }
      let!(:veto) { create :map_veto, company: company1, map: map1 }

      it "excludes the vetoed map" do
        subject
        expect(battle.reload.map).to eq("4p_Langres")
      end
    end

    context "when all matching maps are vetoed" do
      let!(:map1) { create :map, name: "4p_Arras", enabled: true }
      let!(:veto1) { create :map_veto, company: company1, map: map1 }

      it "falls back to all size-appropriate maps" do
        subject
        expect(battle.reload.map).to eq("4p_Arras")
      end
    end

    context "when no maps match the battle size" do
      let!(:wrong_size_map) { create :map, name: "8p_BigMap", enabled: true }

      it "returns nil and does not set a map" do
        expect(subject).to be_nil
        expect(battle.reload.map).to be_nil
      end
    end

    context "when no maps are enabled" do
      let!(:disabled_map) { create :map, name: "4p_Arras", enabled: false }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with different battle sizes" do
      let!(:small_map) { create :map, name: "2p_Duel", enabled: true }
      let!(:large_map) { create :map, name: "4p_Arras", enabled: true }

      it "selects a 2p map for a 1v1 battle" do
        battle.update!(size: 1)
        subject
        expect(battle.reload.map).to eq("2p_Duel")
      end

      it "selects a 4p map for a 2v2 battle" do
        battle.update!(size: 2)
        subject
        expect(battle.reload.map).to eq("4p_Arras")
      end
    end
  end
end