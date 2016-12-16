class GamesController < ApplicationController
    def new
        @new_game = Game.new
    end

    def create
        key = params[:game][:key]
        g = Game.find_by(key: key)
        if g
            flash[:danger] = "That key is taken. Please use another"
            @new_game = Game.new(game_params)
            render 'new'
            return
        end

        @created_game = Game.create(game_params)
        create_teams(params[:teams], @created_game)

        if @created_game.errors.any?
            s = ""
            @created_game.errors.full_messages.each do |msg|
                s += msg
            end
            flash[:danger] = s
            @new_game = @created_game
            render 'new'
        else
            flash[:success] = "Game created successfully"
            redirect_to game_path(@created_game)
        end
    end

    def show
        @game = Game.find(params[:id])
        @teams = @game.teams
        @admin = @game.key == params[:key]
        puts "PARAMS: #{params}"
        @key = params[:key]
    end

    #add players to the game
    def add_players
        @game = Game.find(params[:id])
        success = true
        players = []
        @game.teams.each do |team|
            temp = add_players_helper(team, params[team.name.to_sym])
            #error getting player names, stop
            if temp == nil
                #update error msg once added functionality
                flash[:danger] = "Error adding players"
                success = false
                break
            end

            players = players.concat( temp )
        end
        if success
            flash[:success] = "Success"

            #save all successfully created players
            Player.transaction do
                players.each(&:save!)
            end
        end

        redirect_to action: 'show', id: @game.id, key: params[:key]
    end

    #Assign all the targets then render page to view
    def assign_targets
        @game = Game.find(params[:id])
        
        teams = @game.assign_targets
        if not teams
            #if unsuccessful, redirect to show page
            flash[:danger] = "Error assigning targets"
            redirect_to action: 'show', id: @game.id
            return
        end

        redirect_to action: 'show', id: @game.id, key: params[:key]
    end

    def life_update
        action = params[:act]
        game = Game.find(params[:id])

        if action == "suicide"
            victim = Player.find(params[:player])
            killer = Player.find_by(target_id: victim.id)

            killer.update_attributes(target_id: victim.target_id) #assign killer their target
            victim.update_attributes(alive: false, deaths: victim.deaths + 1, target_id: nil)
        elsif action == "kill"
            killer = Player.find(params[:player])
            victim = Player.find(killer.target_id)

            killer.update_attributes(kills: killer.kills + 1, target_id: victim.target_id)
            victim.update_attributes(alive: false, deaths: victim.deaths + 1, 
                                     target_id: nil)
        elsif action == "revive"
            player = Player.find(params[:player])
            player.update_attribute(:alive, true)
        end
        redirect_to action: 'show', id: game.id, key: params[:key]
    end

    private
    def game_params 
        params.require(:game).permit(:title, :description, :key)
    end

    def create_teams(text, game)
        toks = text.split(',')
        toks.each do |t|
            game.teams << Team.create(name: t, game_id: game.id)
        end
    end

    #take in the text input and the team and add people to game
    def add_players_helper(team, input)
        names = input.split(',')
        players = []
        names.each do |name|
            player = Player.new( name: name, team_id: team.id )
            players << player
        end

        return players 
    end

end
