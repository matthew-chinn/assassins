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
