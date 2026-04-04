require "rails_helper"

RSpec.describe Map, type: :model do
  describe "associations" do
    it { should have_many(:map_vetoes).dependent(:destroy) }
  end

  describe "validations" do
    subject { create :map }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:category) }
  end

  describe "scopes" do
    describe ".enabled" do
      let!(:enabled_map) { create :map, enabled: true }
      let!(:disabled_map) { create :map, enabled: false }

      it "returns only enabled maps" do
        expect(Map.enabled).to include(enabled_map)
        expect(Map.enabled).not_to include(disabled_map)
      end
    end
  end
end