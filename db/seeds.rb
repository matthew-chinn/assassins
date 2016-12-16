# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

game = Game.create(title: "Sample", description: "Test out application", key: "123")

alpha = [ "Matthew", "Brandon", "William", "Brad", "Byung" ]
phi = ["Sean", "Evan", "Grant"]
omega = ["Rebekkah", "Amanda", "Tien", "Colette"]
rho = ["Bill", "Bob", "Robert", "Will"]
pi = ["Apple", "Peach", "Blueberry", "Chicken"]

families = {"Alpha" => alpha, 
            "Phi" => phi,
            "Omega" => omega, 
            "Rho" => rho, 
            "Pi" => pi}      

families.each do |family, people|
    t = Team.create(name: family, game_id: game.id)
    people.each do |person|
        Player.create(name: person, team_id: t.id, team: t, contact: "7dilbertnerd@gmail.com", phone: false)
    end
end

game = Game.create(title: "Small Game", description: "Test out application", key: "asdf")
t1 = ["Bill", "Bob", "Robert", "Will"]
t2 = ["Apple", "Peach", "Blueberry", "Chicken"]

families = {"T1" => t1, 
            "T2" => t2}      

families.each do |family, people|
    t = Team.create(name: family, game_id: game.id)
    people.each do |person|
        Player.create(name: person, team_id: t.id, team: t, contact: "7dilbertnerd@gmail.com", phone: false)
    end
end
