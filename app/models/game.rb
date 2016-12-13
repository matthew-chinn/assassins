class Game < ActiveRecord::Base
    has_many :teams
    has_many :players, through: :teams, dependent: :destroy

    #assign targets with the following algorithm:
    #
    #return teams_hash(alive) 
    def assign_targets
        res = {}
        team_hash = teams_hash(true)
        teams = team_hash.keys

        team_counts = teams.map{ |team| team.count }
        total_count = team_counts.reduce(:+)

        if not Game.possible_to_match_all?(team_counts)
            #what to do here
            #return {}
        end

        #to test edge_set, should be changed later
        return edge_set
    end

    #return hash of team to its players
    #if alive is true, only include players that are alive
    def teams_hash(alive_only = false)
        res = {}
        self.teams do |team|
            if alive_only
                res[team] = Player.where(team_id: team.id, alive: true)
            else
                res[team] = Player.where(team_id: team.id)
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

    def edge_set
        set = Set.new
        self.teams.each do |team1|
            self.teams.each do |team2|
                if team1 != team2
                    set.add( UnDirectedEdge.new(team1,team2) )
                end
            end
        end
        return set
    end
end
