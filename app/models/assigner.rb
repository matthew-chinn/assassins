#helper class to assign targets
class Assigner
    #team_hash: Team model object => it's players that need to be assigned
    #type: "team" or "free, depending on if free for all or team
    #Algorithm for team assignments:
    #Create array of players, ordered by team
    #Select team with highest number of players to be assigned
    #Randomly assign them to a player who hasn't been assigned yet
    #If there are no players left that haven't been assigned
    #Reassign people until works
    def self.assign_targets(team_hash, type)
        require 'priority_queue'
        @queue = PriorityQueue.new
        if type == "free"
            return assign_targets_free(team_hash)
        else
            return assign_targets_team(team_hash)
        end
    end

    def self.assign_targets_free(team_hash)
        @players = [] #array of players to be assigned
        team_hash.each do |team, players|
            players.each do |player|
                if player.alive
                    @players << player
                end
            end
        end
        @assigned_indices = Set.new #set of indices of players already assigned

        return assign_targets_free_helper
    end

    def self.assign_targets_team(team_hash)
        @players = [] #array of players to be assigned
        @assigned_indices = Set.new #set of indices of players already assigned
        @team_to_index = Hash.new #team to its index in array of players
        @team_to_count = Hash.new #team to its count of players

        #populate priority queue, hashes, players array
        populate_collections(team_hash)

        total_count = @team_to_count.values.reduce(:+)
        if total_count == 2
            return assign_2_targets(team_hash)
        end

        #current player we are assigning
        @team_to_curr_index = @team_to_index.clone 
        @players_to_reassign = [] #if failed to assign, try again

        assign_targets_team_helper

        if @players_to_reassign.count > 0
            @available_people = []
            @players.each_with_index do |player,i| #remove people already assigned
                if not @assigned_indices.include? i
                    @available_people << player
                end
            end

            @players_to_reassign.each do |player|
                res = reassign_player(player)
                if not res
                    #reassignment is unsuccessful, try again without team
                    #restriction
                    reassign_player(player, false)
                end
            end

        end

        save_players(@players)
        return true
    end

    def self.assign_2_targets(team_hash)
        #only time people can have each other as targets
        success = true

        teams = team_hash.keys
        p1 = teams[0].players.first
        p2 = teams[1].players.first

        success = success and p1.update_attribute(:target_id,  p2.id)
        success = success and p2.update_attribute(:target_id,  p1.id)

        return success
    end

    private
    def self.populate_collections(team_hash)
        team_hash.keys.each do |team|
            @team_to_index[team] = @players.count
            @team_to_count[team] = team_hash[team].count

            #negative because priority queue takes min
            @queue[team] = -team_hash[team].count

            team_hash[team].each do |player|
                if player.alive
                    @players << player
                end
            end
        end
    end

    #attempts to assign everyone, if unsuccessful, adds to @players_to_reassign
    def self.assign_targets_team_helper
        while @queue.count > 0 do
            team = @queue.min[0] #queue.min seems to return an array including value
            player_to_assign = @players[@team_to_curr_index[team]]                

            assigned_successfully = attempt_to_assign_player_team(player_to_assign, team)
            
            if not assigned_successfully #update count of players to be assigned
                @players_to_reassign << player_to_assign
            end

            if @queue.min[1] == -1
                @queue.delete_min #last player from that team
            else
                @queue[team] = @queue[team] + 1
            end
        end
    end

    def self.attempt_to_assign_player_team(player_to_assign, team)
        #number of players available to assign to is equal to total 
        #number of players minus the number of players on this team
        potential_indices = (0...(@players.count - @team_to_count[team])).to_a

        #reorder indices randomly to act as random generator
        #use instead of random generator to prevent duplicates
        potential_indices = potential_indices.sample(potential_indices.count) 

        #repeat until we have a good assignment or there are no prople to be 
        #assigned, may have to try reassigning
        while potential_indices.count > 0 do
            rand = potential_indices.pop

            #move past the current team's indices, then add rand
            index = (@team_to_index[team] + @team_to_count[team] + 
                     rand) % @players.count

            if @assigned_indices.include? index || @players[index].target_id == player_to_assign.id
                #try another index because this person has been assigned
                #or that person's target is this player
                next 
            end

            #the person is a valid assignment
            player_to_assign.target_id = @players[index].id
            @assigned_indices.add(index)                             
            @team_to_curr_index[team] = @team_to_curr_index[team] + 1
            return true
        end
        
        @team_to_curr_index[team] = @team_to_curr_index[team] + 1
        return false
    end

    def self.assign_targets_free_helper
        @players.each_with_index do |player, i|
            assign_player_free(player, i)
        end

        save_players(@players)
        return true
    end

    #i is the index location of that player
    def self.assign_player_free(player_to_assign, i)
        #number of players available to assign 
        potential_indices = (1...@players.count).to_a

        #reorder indices randomly to act as random generator
        #use instead of random generator to prevent duplicates
        potential_indices = potential_indices.sample(potential_indices.count) 

        #repeat until we have a good assignment or there are no people to be 
        #assigned, may have to try reassigning
        while potential_indices.count > 0 do
            rand = potential_indices.pop

            #move past the current team's indices, then add rand
            index = (i + rand) % @players.count

            if @assigned_indices.include? index || 
               @players[index].target_id == player_to_assign.id
                #try another index because this person has been assigned
                #or that person's target is this player
                next 
            end

            #the person is a valid assignment
            player_to_assign.target_id = @players[index].id
            @assigned_indices.add(index)                             
            return true
        end

        #if hasnt been assigned, then that means only unassigned player left is
        #this current player_to_assign, switch with anyone
        @players.each do |player|
            if player == player_to_assign
                next
            end
            player_to_assign.target_id = player.target_id
            player.target_id = player_to_assign.id
            return true
        end

        return false #somehow couldnt assign player
    end

    #in team games, match this player to a valid target
    #if team is true, then only reassign to players of other teams
    #if team is false, then allow reassignments to players of same team
    def self.reassign_player(player, team = true)
        if not team #assign to anyone that isnt the player themself
            @available_people.each do |potential_target|
                if potential_target != player
                    player.target_id = potential_target.id
                    @available_people.delete(potential_target)
                    return true
                end
            end

            #if the only available person is the same player themself
            #switch with anyone else
            @players.each do |other|
                if not other.alive or player == other
                    next
                end
                player.target_id = other.target_id
                other.target_id = @available_people.first.id
                return true
            end
        end

        player_team = Team.find(player.team_id)
        @players.each do |other_player| #someone whose target we will take
            next if !other_player.alive
            next if other_player.target_id == nil

            other_team = Team.find(other_player.team_id)
            next if other_team == player_team #same team, has same problem

            other_target = Player.find(other_player.target_id)
            other_target_team = Team.find(other_target.team_id)
            next if other_target_team == player_team #invalid target

            @available_people.each do |potential_target|
                target_team = Team.find(potential_target.team_id)
                next if other_team == target_team 
                player.update_attribute(:target_id, other_player.target_id)
                other_player.update_attribute(:target_id, potential_target.id)
                return true
            end
        end
        return false
    end

    def self.save_players(players)
        #save to database
        players.each do |p|
            p.save
        end
    end
end
