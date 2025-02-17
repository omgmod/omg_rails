require "rails_helper"

RSpec.describe Snapshot::Creator do
  let!(:ruleset) { create :ruleset }
  let!(:player) { create :player }
  let(:name) { "New company" }
  let(:unit1) { create :unit }
  let(:unit2) { create :unit }
  let(:unit3) { create :unit }
  let(:offmap1) { create :offmap, ruleset: ruleset }
  let(:offmap2) { create :offmap, ruleset: ruleset }
  let(:upgrade1) { create :upgrade }
  let(:upgrade2) { create :upgrade }
  let(:upgrade3) { create :upgrade }

  let!(:active_company) { create :active_company, player: player, ruleset: ruleset }
  let(:faction) { active_company.faction }
  let(:doctrine) { active_company.doctrine }
  let!(:available_unit1) { create :available_unit, unit: unit1, company: active_company, man: 300, mun: 60, fuel: 0, available: 10, resupply: 5, resupply_max: 10 }
  let!(:available_unit2) { create :available_unit, unit: unit2, company: active_company, man: 100, mun: 0, fuel: 20, available: 80, resupply: 10, resupply_max: 99 }
  let!(:available_unit3) { create :available_unit, unit: unit3, company: active_company, man: 250, mun: 0, fuel: 40, available: 8, resupply: 4, resupply_max: 16 }
  let!(:available_upgrade1) { create :available_upgrade, upgrade: upgrade1, unit: unit1, company: active_company, man: 0, mun: 20, fuel: 0 }
  let!(:available_upgrade2) { create :available_upgrade, upgrade: upgrade1, unit: unit2, company: active_company, man: 0, mun: 20, fuel: 0 }
  let!(:available_upgrade3) { create :available_upgrade, upgrade: upgrade2, unit: unit2, company: active_company, man: 50, mun: 20, fuel: 20 }
  let!(:available_upgrade4) { create :available_upgrade, upgrade: upgrade3, unit: unit2, company: active_company, man: 0, mun: 0, fuel: 75 }

  let(:new_company) { SnapshotCompany.last }
  subject { described_class.new(player, name, active_company.id).create }

  before do
    create :company_stats, company: active_company, wins_1v1: 10, losses_1v1: 5
    create :transport_allowed_unit, transport: unit3, allowed_unit: unit1
    create :transport_allowed_unit, transport: unit3, allowed_unit: unit2
  end

  describe "#create" do
    it "clones the company" do
      expect { subject }.to change { Company.count }.by(1)
                                                    .and change { SnapshotCompany.count }.by(1)
                                                                                         .and change { ActiveCompany.count }.by(0)
      expect(SnapshotCompany.last.name).to eq name
    end

    it "clones the company stats" do
      expect { subject }.to change { CompanyStats.count }.by(1)
      expect(new_company.company_stats.wins_1v1).to eq 10
      expect(new_company.company_stats.losses_1v1).to eq 5
    end

    it "clones the available units" do
      expect { subject }.to change { AvailableUnit.count }.by(3)
      expect(new_company.available_units.count).to eq 3
      au1 = new_company.available_units.find_by(unit: unit1)
      expect(au1.company).to eq new_company
      expect(au1.man).to eq 300
      expect(au1.mun).to eq 60
      expect(au1.fuel).to eq 0
      expect(au1.available).to eq 10
      expect(au1.resupply).to eq 5
      expect(au1.resupply_max).to eq 10

      au2 = new_company.available_units.find_by(unit: unit2)
      expect(au2.company).to eq new_company
      expect(au2.man).to eq 100
      expect(au2.mun).to eq 0
      expect(au2.fuel).to eq 20
      expect(au2.available).to eq 80
      expect(au2.resupply).to eq 10
      expect(au2.resupply_max).to eq 99

      au3 = new_company.available_units.find_by(unit: unit3)
      expect(au3.company).to eq new_company
      expect(au3.man).to eq 250
      expect(au3.mun).to eq 0
      expect(au3.fuel).to eq 40
      expect(au3.available).to eq 8
      expect(au3.resupply).to eq 4
      expect(au3.resupply_max).to eq 16
    end

    it "clones the available upgrades" do
      expect { subject }.to change { AvailableUpgrade.count }.by(4)
      expect(new_company.available_upgrades.count).to eq 4
      au1 = new_company.available_upgrades.find_by(upgrade: upgrade1, unit: unit1)
      expect(au1.company).to eq new_company
      expect(au1.man).to eq 0
      expect(au1.mun).to eq 20
      expect(au1.fuel).to eq 0

      au2 = new_company.available_upgrades.find_by(upgrade: upgrade1, unit: unit2)
      expect(au2.company).to eq new_company
      expect(au2.man).to eq 0
      expect(au2.mun).to eq 20
      expect(au2.fuel).to eq 0

      au3 = new_company.available_upgrades.find_by(upgrade: upgrade2, unit: unit2)
      expect(au3.company).to eq new_company
      expect(au3.man).to eq 50
      expect(au3.mun).to eq 20
      expect(au3.fuel).to eq 20

      au4 = new_company.available_upgrades.find_by(upgrade: upgrade3, unit: unit2)
      expect(au4.company).to eq new_company
      expect(au4.man).to eq 0
      expect(au4.mun).to eq 0
      expect(au4.fuel).to eq 75
    end

    context "when there are available offmaps" do
      let!(:available_offmap1) { create :available_offmap, offmap: offmap1, company: active_company, available: 2, max: 2, mun: 100 }
      let!(:available_offmap2) { create :available_offmap, offmap: offmap2, company: active_company, available: 1, max: 2, mun: 60 }

      it "clones the available offmaps" do
        expect { subject }.to change { AvailableOffmap.count }.by(2)
        expect(new_company.available_offmaps.count).to eq 2
        ao1 = new_company.available_offmaps.find_by(offmap: offmap1)
        expect(ao1.company).to eq new_company
        expect(ao1.offmap).to eq offmap1
        expect(ao1.available).to eq 2
        expect(ao1.max).to eq 2
        expect(ao1.mun).to eq 100
        ao2 = new_company.available_offmaps.find_by(offmap: offmap2)
        expect(ao2.company).to eq new_company
        expect(ao2.offmap).to eq offmap2
        expect(ao2.available).to eq 1
        expect(ao2.max).to eq 2
        expect(ao2.mun).to eq 60
      end
    end

    context "when there are squads" do
      let!(:squad1) { create :squad, company: active_company, available_unit: available_unit1, tab_category: "core", category_position: 0 }
      let!(:squad2) { create :squad, company: active_company, available_unit: available_unit2, tab_category: "infantry", category_position: 0 }
      let!(:squad3) { create :squad, company: active_company, available_unit: available_unit3, tab_category: "infantry", category_position: 1 }
      let!(:squad4) { create :squad, company: active_company, available_unit: available_unit1, tab_category: "infantry", category_position: 1 }
      let!(:squad5) { create :squad, company: active_company, available_unit: available_unit1, tab_category: "infantry", category_position: 1 }
      let!(:squad6) { create :squad, company: active_company, available_unit: available_unit3, tab_category: "support", category_position: 5 }
      let!(:squad7) { create :squad, company: active_company, available_unit: available_unit2, tab_category: "support", category_position: 5 }
      let(:au1) { new_company.available_units.find_by(unit: unit1) }
      let(:au2) { new_company.available_units.find_by(unit: unit2) }
      let(:au3) { new_company.available_units.find_by(unit: unit3) }

      it "clones the available squads" do
        expect { subject }.to change { Squad.count }.by(7)
        expect(new_company.squads.count).to eq 7
        expect(new_company.squads.where(available_unit: au1, tab_category: "core", category_position: 0).count).to eq 1
        expect(new_company.squads.where(available_unit: au2, tab_category: "infantry", category_position: 0).count).to eq 1
        expect(new_company.squads.where(available_unit: au3, tab_category: "infantry", category_position: 1).count).to eq 1
        expect(new_company.squads.where(available_unit: au1, tab_category: "infantry", category_position: 1).count).to eq 2
        expect(new_company.squads.where(available_unit: au3, tab_category: "support", category_position: 5).count).to eq 1
        expect(new_company.squads.where(available_unit: au2, tab_category: "support", category_position: 5).count).to eq 1
      end

      context "when there are transported squads" do
        before do
          create :transported_squad, transport_squad: squad3, embarked_squad: squad4
          create :transported_squad, transport_squad: squad3, embarked_squad: squad5
          create :transported_squad, transport_squad: squad6, embarked_squad: squad7
        end

        it "clones the TransportedSquads" do
          expect { subject }.to change { TransportedSquad.count }.by 3
          transport = new_company.squads.find_by(available_unit: au3, tab_category: "infantry", category_position: 1)
          transported_squad_records = TransportedSquad.where(transport_squad: transport)
          embarked_squad_ids = new_company.squads.where(available_unit: au1, tab_category: "infantry", category_position: 1).pluck(:id)
          expect(transported_squad_records.count).to eq 2
          expect(transported_squad_records.map { |ts| ts.embarked_squad_id }).to match_array embarked_squad_ids

          transport = new_company.squads.find_by(available_unit: au3, tab_category: "support", category_position: 5)
          transported_squad_records = TransportedSquad.where(transport_squad: transport)
          embarked_squad_ids = new_company.squads.where(available_unit: au2, tab_category: "support", category_position: 5).pluck(:id)
          expect(transported_squad_records.count).to eq 1
          expect(transported_squad_records.map { |ts| ts.embarked_squad_id }).to match_array embarked_squad_ids
        end
      end

      context "when there are squad upgrades" do
        let(:new_available_upgrade1) { new_company.available_upgrades.find_by(upgrade: upgrade1, unit: unit1) }
        let(:new_available_upgrade2) { new_company.available_upgrades.find_by(upgrade: upgrade1, unit: unit2) }
        let(:new_available_upgrade3) { new_company.available_upgrades.find_by(upgrade: upgrade2, unit: unit2) }
        let(:new_available_upgrade4) { new_company.available_upgrades.find_by(upgrade: upgrade3, unit: unit2) }

        before do
          create :squad_upgrade, squad: squad1, available_upgrade: available_upgrade1
          create :squad_upgrade, squad: squad2, available_upgrade: available_upgrade2
          create :squad_upgrade, squad: squad2, available_upgrade: available_upgrade3
          create :squad_upgrade, squad: squad4, available_upgrade: available_upgrade1
          create :squad_upgrade, squad: squad5, available_upgrade: available_upgrade1
          create :squad_upgrade, squad: squad7, available_upgrade: available_upgrade4
        end

        it "clones the SquadUpgrades" do
          expect { subject }.to change { SquadUpgrade.count }.by 6
          expect(new_company.squad_upgrades.count).to eq 6

          s1 = new_company.squads.find_by(available_unit: au1, tab_category: "core", category_position: 0)
          expect(s1.squad_upgrades.count).to eq 1
          su1 = s1.squad_upgrades.first
          expect(su1.available_upgrade).to eq new_available_upgrade1

          s2 = new_company.squads.find_by(available_unit: au2, tab_category: "infantry", category_position: 0)
          expect(s2.squad_upgrades.count).to eq 2
          expect(s2.squad_upgrades.where(available_upgrade: new_available_upgrade2).count).to eq 1
          expect(s2.squad_upgrades.where(available_upgrade: new_available_upgrade3).count).to eq 1

          s4 = new_company.squads.find_by(available_unit: au1, tab_category: "infantry", category_position: 1)
          expect(s4.squad_upgrades.count).to eq 1
          expect(s4.squad_upgrades.where(available_upgrade: new_available_upgrade1).count).to eq 1

          s5 = new_company.squads.find_by(available_unit: au1, tab_category: "infantry", category_position: 1)
          expect(s5.squad_upgrades.count).to eq 1
          expect(s5.squad_upgrades.where(available_upgrade: new_available_upgrade1).count).to eq 1

          s7 = new_company.squads.find_by(available_unit: au2, tab_category: "support", category_position: 5)
          expect(s7.squad_upgrades.count).to eq 1
          expect(s7.squad_upgrades.where(available_upgrade: new_available_upgrade4).count).to eq 1
        end
      end
    end

    context "when there are company callin modifiers" do
      let!(:callin_modifier1) { create :callin_modifier }
      let!(:callin_modifier2) { create :callin_modifier }

      before do
        create :company_callin_modifier, company: active_company, callin_modifier: callin_modifier1
        create :company_callin_modifier, company: active_company, callin_modifier: callin_modifier2
      end

      it "clones the company callin modifiers" do
        expect { subject }.to change { CompanyCallinModifier.count }.by 2
        expect(new_company.company_callin_modifiers.pluck(:callin_modifier_id)).to match_array [callin_modifier1.id, callin_modifier2.id]
      end
    end

    context "when there are company unlocks" do
      let!(:unlock1) { create :unlock, ruleset: ruleset }
      let!(:unlock2) { create :unlock, ruleset: ruleset }
      let!(:unlock3) { create :unlock, ruleset: ruleset }
      let!(:doc_unlock1) { create :doctrine_unlock, unlock: unlock1, doctrine: doctrine, ruleset: ruleset, row: 1 }
      let!(:doc_unlock2) { create :doctrine_unlock, unlock: unlock2, doctrine: doctrine, ruleset: ruleset, row: 2 }
      let!(:doc_unlock3) { create :doctrine_unlock, unlock: unlock3, doctrine: doctrine, ruleset: ruleset, row: 3 }

      before do
        create :company_unlock, company: active_company, doctrine_unlock: doc_unlock1
        create :company_unlock, company: active_company, doctrine_unlock: doc_unlock3
      end

      it "clones the company unlocks" do
        expect { subject }.to change { CompanyUnlock.count }.by 2
        expect(new_company.company_unlocks.pluck(:doctrine_unlock_id)).to match_array [doc_unlock1.id, doc_unlock3.id]
      end
    end

    context "when there are company offmaps" do
      let!(:available_offmap1) { create :available_offmap, company: active_company, offmap: offmap1 }
      let!(:available_offmap2) { create :available_offmap, company: active_company, offmap: offmap2 }

      before do
        create :company_offmap, company: active_company, available_offmap: available_offmap1
        create :company_offmap, company: active_company, available_offmap: available_offmap1
        create :company_offmap, company: active_company, available_offmap: available_offmap2
      end

      it "clones the company offmaps" do
        expect { subject }.to change { CompanyOffmap.count }.by 3
        ao1 = new_company.available_offmaps.find_by(offmap: offmap1)
        ao2 = new_company.available_offmaps.find_by(offmap: offmap2)
        expect(new_company.company_offmaps.pluck(:available_offmap_id))
          .to match_array [ao1.id, ao1.id, ao2.id]
      end
    end

    context "when there are company resource bonuses" do
      let!(:resource_bonus_man) { create :resource_bonus, ruleset: ruleset }
      let!(:resource_bonus_mun) { create :resource_bonus, ruleset: ruleset, resource: "mun" }

      before do
        create :company_resource_bonus, company: active_company, resource_bonus: resource_bonus_man, level: 3
        create :company_resource_bonus, company: active_company, resource_bonus: resource_bonus_mun, level: 2
      end

      it "clones the company resource bonuses" do
        expect { subject }.to change { CompanyResourceBonus.count }.by 2
        crb1 = new_company.company_resource_bonuses.find_by(resource_bonus: resource_bonus_man)
        expect(crb1.level).to eq 3
        crb2 = new_company.company_resource_bonuses.find_by(resource_bonus: resource_bonus_mun)
        expect(crb2.level).to eq 2
      end
    end

    context "when the player does not own the source company" do
      let!(:player2) { create :player }
      it "raises an error" do
        expect { described_class.new(player2, name, active_company.id).create }.to raise_error Snapshot::Creator::SnapshotCreatorValidationError,
                                                                                         "Player #{player2.name} does not own source company #{active_company.id}"
      end
    end

    context "when the player has the limit of snapshot companies" do
      before do
        12.times do
          create :snapshot_company, player: player, ruleset: ruleset
        end
      end
      it "raises an error" do
        expect { subject }.to raise_error(
          Snapshot::Creator::SnapshotCreatorValidationError,
          "Player #{player.name} has the limit of #{SnapshotCompany::LIMIT} Snapshot Companies and cannot create another one.")
      end
    end
  end
end
