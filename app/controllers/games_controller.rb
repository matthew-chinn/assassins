class GamesController < ApplicationController
    def new
        @new_game = Game.new
    end

    def create
        @created_game = Game.create(game_params)
        create_teams(params[:teams], @created_game)

        if @created_game.errors.any?
            flash[:danger] = "New game could not be made"
            @new_game = @created_game
            render 'new'
        else
            flash[:success] = "Game created successfully"
            redirect_to game_path(@created_game)
        end
    end

    def show
        @game = Game.find(params[:id])
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

        redirect_to action: 'show', id: @game.id
    end

    #Assign all the targets then render page to view
    def assign_targets
        @game = Game.find(params[:id])
        
        #Hash of teams to players that are still alive
        teams = @game.assign_targets
        if not teams
            #if unsuccessful, redirect to show page
            flash[:danger] = "Error assigning targets"
            redirect_to action: 'show', id: @game.id
            return
        end

        redirect_to action: 'view_targets', id: @game.id
    end

    def view_targets
        @game = Game.find(params[:id])
        @teams = @game.teams_hash(true)
        render 'targets'
    end

    private
    def game_params 
        params.require(:game).permit(:title, :description, :admin_email)
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
