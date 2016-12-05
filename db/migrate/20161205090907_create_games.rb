class CreateGames < ActiveRecord::Migration
    def change
        create_table :games do |t|
            t.string :title
            t.string :description
            t.string :admin_email
            t.string :password

            t.timestamps null: false
        end
    end
end
