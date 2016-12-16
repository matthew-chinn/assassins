require 'test_helper'

class GameTest < ActiveSupport::TestCase
    test "Game.possible_to_match_all?" do
        assert_not Game.possible_to_match_all?([10,5,3])
        assert Game.possible_to_match_all?([10,5,5])
        assert_not Game.possible_to_match_all?([10])
    end

    test "Game.assign_targets 2 players" do
        g = Game.create(title: "title", key: "123")
        t1 = Team.create(game_id: g.id, name: "A")
        t2 = Team.create(game_id: g.id, name: "B")

        p1 = Player.create(name: "Bill", team_id: t1.id)
        p2 = Player.create(name: "Bob", team_id: t2.id)

        g.assign_targets

        p1.reload
        p2.reload

        assert p1.target_id == p2.id
        assert p2.target_id == p1.id
    end

    test "Game.assign_targets 2 teams, 10 players each" do
        g = Game.create(title: "title", key: "123")
        team_names = [ "A", "B"]
        teams_hash = {}

        team_names.each do |name|
            t = Team.create(game_id: g.id, name: name)

            players = []
            (1..10).each do |x|
                player = Player.create(name: "#{name}Player#{x}", team_id: t.id) 
                players << player
            end

            teams_hash[t] = players
        end

        assert g.assign_targets
        assert check_targets(teams_hash)
    end

    test "Game.assign_targets 2 teams, different players each" do
        g = Game.create(title: "title", key: "123")
        team_names = [ "A", "B" ]
        player_counts = [2, 1]
        teams_hash = {}

        team_names.each_with_index do |name, i|
            t = Team.create(game_id: g.id, name: name)

            players = []
            (1..player_counts[i]).each do |x|
                player = Player.create(name: "#{name}Player#{x}", team_id: t.id) 
                players << player
            end

            teams_hash[t] = players
        end

        assert_not g.assign_targets
    end

    test "Game.assign_targets 3 teams, 5 players each" do
        g = Game.create(title: "title", key: "123")
        team_names = [ "A", "B", "C"]
        teams_hash = {}

        team_names.each do |name|
            t = Team.create(game_id: g.id, name: name)

            players = []
            (1..5).each do |x|
                player = Player.create(name: "#{name}Player#{x}", team_id: t.id) 
                players << player
            end

            teams_hash[t] = players
        end

        assert g.assign_targets
        assert check_targets(teams_hash)
    end

    test "Game.assign_targets 5 teams, different players each" do
        g = Game.create(title: "title", key: "123")
        team_names = [ "A", "B", "C", "D", "E"]
        player_counts = [25, 11, 14, 7, 28]
        teams_hash = {}

        team_names.each_with_index do |name, i|
            t = Team.create(game_id: g.id, name: name)

            players = []
            (1..player_counts[i]).each do |x|
                player = Player.create(name: "#{name}Player#{x}", team_id: t.id) 
                players << player
            end

            teams_hash[t] = players
        end

        assert g.assign_targets
        assert check_targets(teams_hash)
    end

    #make sure all players are assigned target id's and that their targets
    #are on different teams than their own and unique targets
    def check_targets(teams_hash)
        set = Set.new
        teams_hash.keys.each do |team|
            team.players.each do |player|
                player.reload
                if player.target_id == nil
                    return false
                end

                target = Player.find(player.target_id)
                target_team = Team.find(target.team_id)
                if target_team == team or set.include?(player.target_id)
                    return false
                end
                set.add(player.target_id)
            end
        end
        return true
    end
end
