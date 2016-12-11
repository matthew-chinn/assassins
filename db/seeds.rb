# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

game = Game.create(title: "Sample", description: "Test out application", admin_email: "chinnymasta@gmail.com", password: "123")

alpha = [ "Matthew", "Brandon", "William", "Brad", "Byung" ]
phi = ["Sean", "Evan", "Grant"]
omega = ["Rebekkah", "Amanda", "Tien", "Colette"]
rho = ["Bill", "Bob", "Robert", "Will"]
pi = ["Apple", "Peach", "Blueberry", "Chicken"]

families = {"alpha" => alpha, 
            "phi" => phi,
            "oemga" => omega, 
            "rho" => rho, 
            "pi" => pi}      

families.each do |family, people|
    people.each do |person|
        Player.create(name: person, game_id: game.id, family: family)
    end
end

