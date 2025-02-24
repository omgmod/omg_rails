require "rails_helper"

RSpec.describe BattleService do
  let!(:player) { create :player }
  let!(:player_rating) { create :player_rating, player: player }
  subject { described_class.new(player) }

  let!(:ruleset) { create :ruleset }
  let(:faction1) { create :faction }
  let(:doctrine1) { create :doctrine, faction: faction1 }
  let(:faction2) { create :faction, :axis }
  let(:doctrine2) { create :doctrine, faction: faction2 }
  let(:size) { 1 }
  let(:unit1) { create :unit }
  let(:company) { create :active_company, player: player, ruleset: ruleset, faction: faction1, doctrine: doctrine1 }

  before do
    available_unit = create :available_unit, company: company, unit: unit1, pop: 10
    create :squad, company: company, available_unit: available_unit, pop: available_unit.pop
  end

  describe "#create_battle" do
    let(:name) { "test battle" }

    context "when the player is not already in a battle" do
      it "creates the battle successfully" do
        expect { subject.create_battle(name, 1, ruleset.id, company.id) }.to change { Battle.count }.by(1).and change { BattlePlayer.count }.by(1)
        expect(Battle.last.name).to eq name
      end

      it "associates the player to the battle" do
        subject.create_battle(name, 1, ruleset.id, company.id)
        expect(Battle.last.battle_players.find_by(player: player)).not_to be nil
      end
    end

    context "when the player is already in a battle" do
      before do
        battle = create :battle, ruleset: ruleset
        create :battle_player, battle: battle, player: player, company: company
      end
      it "fails to create a battle" do
        expect { subject.create_battle(name, 1, ruleset.id, company.id) }
          .to raise_error(BattleService::BattleValidationError,
                          "Player #{player.name} cannot create or join a battle while in an existing battle.")
      end
    end
  end

  describe "#join_battle" do
    # TODO
  end

  describe "#ready_player" do
    # TODO
  end

  describe "#leave_battle" do
    # TODO
  end

  describe "#abandon_battle" do
    # TODO
  end
end
