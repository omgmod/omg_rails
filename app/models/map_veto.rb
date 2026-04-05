class MapVeto < ApplicationRecord
  self.table_name = "map_vetoes"

  belongs_to :company
  belongs_to :map

  validates :map_id, uniqueness: { scope: :company_id }
  validate :competitive_veto_limit

  private

  def competitive_veto_limit
    return unless map&.competitive?

    size_prefix = map.name[/^\d+p/]
    return unless size_prefix

    existing = MapVeto.joins(:map)
                      .where(company_id: company_id)
                      .where(maps: { category: "competitive" })
                      .where("maps.name LIKE ?", "#{size_prefix}_%")
                      .where.not(id: id)

    errors.add(:base, "Company can only veto one competitive map per size") if existing.exists?
  end
end
