class CreateMapVetoes < ActiveRecord::Migration[7.0]
  def change
    create_table :map_vetoes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :map, null: false, foreign_key: true

      t.timestamps
    end

    add_index :map_vetoes, [:company_id, :map_id], unique: true
  end
end
