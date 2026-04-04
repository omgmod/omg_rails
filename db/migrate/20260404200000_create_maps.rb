class CreateMaps < ActiveRecord::Migration[7.0]
  def change
    create_table :maps do |t|
      t.string :name, null: false, comment: "Map name from CDN manifest (e.g. 4p_Arras)"
      t.string :category, null: false, default: "competitive", comment: "Map category: meme or competitive"
      t.boolean :enabled, null: false, default: true, comment: "Whether this map is in the rotation"

      t.timestamps
    end

    add_index :maps, :name, unique: true
    add_index :maps, :category
    add_index :maps, :enabled
  end
end
