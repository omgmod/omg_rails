class UpdatePlayerNameRequired < ActiveRecord::Migration[7.0]
  def change
    change_column_null :players, :name, false
  end
end
