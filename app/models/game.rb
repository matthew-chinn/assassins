class Game < ActiveRecord::Base
    has_many :teams, dependent: :destroy
    has_many :players, through: :teams
    validates :title, presence: true
    validates :key , presence: true

    #assign targets with the following algorithm:
    #
    #return teams_hash(alive) 
    def assign_targets(type = "team")
        res = {}
        #alive players
        team_hash = teams_hash(true)
        teams = team_hash.keys

        return Assigner.assign_targets(team_hash, type)
    end

    #return hash of team to its players
    #if alive is true, only include players that are alive
    def teams_hash(alive_only = false)
        res = {}
        self.teams.each do |team|
            if alive_only
                players = Player.where(team_id: team.id, alive: true)
                res[team] =  players if players.count > 0
            else
                players = Player.where(team_id: team.id)
                res[team] =  players if players.count > 0
            end
        end
        return res
    end

    def update_time
        self.update_attribute(:updated_at, Time.now)
    end

    #merge games by changing the team id of players from the old game to 
    #match the team in the current game with the same name
    #If no team match, keep on their same team
    #Also change team game_id to point to new game
    def merge_with(game)
        if game == self
            return
        end

        name_to_team = {}
        self.teams.each do |team|
            name_to_team[team.name] = team
        end

        other_teams = game.teams
        other_teams.each do |other_team|
            #team name same in both 
            if name_to_team[other_team.name]
                new_team = name_to_team[other_team.name]
                other_team.players.each do |player|
                    player.update_attribute(:team_id, new_team.id)
                end
            #diff team name, update game id of old team
            else
                other_team.update_attribute(:game_id, self.id)
            end
        end
        game.delete 
    end

    private
    #returns if it is possible to match all teams using their counts
    #i.e. if team A has 10, team B has 3, and team C has 4, can't match all of A
    def self.possible_to_match_all?(team_counts)
        copy = Array.new(team_counts)
        #subtract counts from different teams from copy
        #i.e. team A = 10 - 3 - 4, team B = 3 - 10 - 4, team C = 4 - 10 - 3
        team_counts.each_with_index do |elemi, i|
            copy.each_with_index do |elemj, j|
                if j != i 
                    copy[j] = elemj - elemi
                end
            end
        end

        copy.each do |count|
            if count > 0 #cant match them all
                return false
            end
        end
        return true
    end

end
