class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
        t.integer :game_id
        t.string :name
        t.timestamps null: false
    end

    change_table :players do |t|
        t.remove :game_id
        t.integer :team_id
    end
  end
end
