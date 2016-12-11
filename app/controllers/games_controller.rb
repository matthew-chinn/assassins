class GamesController < ApplicationController
    def new
        @new_game = Game.new
    end

    def create
        @created_game = Game.create(game_params)

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
        families = ["alpha", "phi", "omega", "rho", "pi"]
        success = true
        players = []
        families.each do |f|
            temp = add_players_helper(f, params[f.to_sym], @game)
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

    private
    def game_params 
        params.require(:game).permit(:title, :description, :admin_email)
    end

    #take in the text input and the family and add people to game
    def add_players_helper(family, input, game)
        names = input.split(',')
        players = []
        names.each do |name|
            player = Player.new( name: name, game_id: @game.id, family: family)
            players << player
        end

        return players 
    end

end
