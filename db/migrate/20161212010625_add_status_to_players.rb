class AddStatusToPlayers < ActiveRecord::Migration
  def change
      add_column :players, :alive, :boolean, default: true
      add_column :players, :kills, :integer, default: 0
      add_column :players, :deaths, :integer, default: 0
  end
end
