class MapVeto < ApplicationRecord
  self.table_name = "map_vetoes"

  belongs_to :company
  belongs_to :map

  validates :map_id, uniqueness: { scope: :company_id }
  validate :competitive_veto_limit

  private

  def competitive_veto_limit
    return unless map&.competitive?

    existing = MapVeto.joins(:map)
                      .where(company_id: company_id)
                      .where(maps: { category: "competitive" })
                      .where.not(id: id)

    errors.add(:base, "Company can only veto one competitive map") if existing.exists?
  end
end
