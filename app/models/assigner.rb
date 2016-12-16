#helper class to assign targets
class Assigner
    #team_hash: Team model object => it's players that need to be assigned
    #Algorithm:
    #Create array of players, ordered by team
    #Select team with highest number of players to be assigned
    #Randomly assign them to a player who hasn't been assigned yet
    #If there are no players left that haven't been assigned
    #Reassign people until works
    def self.assign_targets(team_hash)
        require 'priority_queue'
        @queue = PriorityQueue.new

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

        attempt_assignments

        @players_to_reassign.each do |player|
            #TODO reassign here
            player.target_id = nil
            puts "NEED TO REASSIGN #{player.name}"
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
            @team_to_count[team] = team.players.count

            #negative because priority queue takes min
            @queue[team] = -team.players.count

            team.players.each do |player|
                @players << player
            end
        end
    end

    #attempts to assign everyone, if unsuccessful, adds to @players_to_reassign
    def self.attempt_assignments
        while @queue.count > 0 do
            team = @queue.min[0] #queue.min seems to return an array including value
            player_to_assign = @players[@team_to_curr_index[team]]                

            assigned_successfully = attempt_to_assign_player(player_to_assign, team)
            
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

    def self.attempt_to_assign_player(player_to_assign, team)
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

            if @assigned_indices.include? index
                next #try another index because this person has been assigned
            end

            #the person is a valid assignment
            player_to_assign.target_id = @players[index].id
            @assigned_indices.add(index)                             
            @team_to_curr_index[team] = @team_to_curr_index[team] + 1
            return true
        end
        
        return false
    end

    def self.save_players(players)
        #save to database
        players.each do |p|
            p.save
            #if p.target_id != nil
            #    puts "Player: #{p.name}, Target: #{Player.find(p.target_id).name}"
            #end
        end
    end
end
