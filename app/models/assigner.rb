#helper class to assign targets
class Assigner
    $rand_gen = Random.new

    #team_hash: Team model object => it's players that need to be assigned
    #Algorithm:
    #Create array of players, ordered by team
    #Select team with highest number of players to be assigned
    #Randomly assign them to a player who hasn't been assigned yet
    #If there are no players left that haven't been assigned
    #Reassign people until works
    def self.assign_targets(team_hash)
        require 'priority_queue'
        queue = PriorityQueue.new

        players = [] #array of players to be assigned
        assigned_indices = Set.new #set of indices of players already assigned
        team_to_index = Hash.new #team to its index in array of players
        team_to_count = Hash.new #team to its count of players

        team_hash.keys.each do |team|
            team_to_index[team] = players.count
            team_to_count[team] = team.players.count

            #negative because priority queue takes min
            queue[team] = -team.players.count

            team.players.each do |player|
                players << player
            end
        end

        #current player we are assigning
        team_to_curr_index = Hash.new(team_to_index) 

        while queue.count > 0 do
            team = queue.min

            player_to_assign = players[team_to_curr_index[team]]                

            while true do
                #number of players available to assign to is equal to total 
                #number of players minus the number of players on this team
                rand = $rand_gen.rand( players.count - team_to_count[team] )


                #clear the current team's index, then add rand
                index = (team_to_index[team] + team_to_count[team] + 
                        rand) % players.count

                if assigned_indices.subset? index
                    next #try another index because this person has been assigned
                end
                
                player_to_assign.target_id = players[index].id
                assigned_indices.add(index)                             
                team_to_curr_index[team] = team_to_curr_index[team] + 1

                if queue.min_value == -1
                    queue.delete_min #last player from that team
                else
                    queue[team] = queue[team] + 1
                end

                break
            end
        end

        #save to database
        players.each do |p|
            p.save
        end
    end
end
