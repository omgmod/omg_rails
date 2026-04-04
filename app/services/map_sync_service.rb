require "http"
require "rexml/document"

class MapSyncService
  MANIFEST_URL = "https://data.omgmod.net/versions/manifest.xml"
  MAP_PATTERN = /^\d+p_/

  def sync
    xml = fetch_manifest
    map_names = parse_map_names(xml)

    created = 0
    map_names.each do |name|
      map = Map.find_or_initialize_by(name: name)
      if map.new_record?
        map.save!
        created += 1
      end
    end

    { total: map_names.size, created: created }
  end

  private

  def fetch_manifest
    response = HTTP.get(MANIFEST_URL)
    raise "Failed to fetch manifest: #{response.status}" unless response.status.success?

    response.body.to_s
  end

  def parse_map_names(xml)
    doc = REXML::Document.new(xml)
    names = []

    doc.elements.each("//directory[@name='Archives']/file") do |file|
      filename = file.attributes["name"]
      next unless filename&.match?(MAP_PATTERN)

      name = filename.sub(/\.sga\z/i, "")
      names << name
    end

    names.uniq
  end
end
