class CreatePlayers < ActiveRecord::Migration
    def change
        create_table :players do |t|
            t.string :name
            t.integer :game_id
            t.string :family

            t.timestamps null: false
        end
    end
end
