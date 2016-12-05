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

    private
    def game_params 
        params.require(:game).permit(:title, :description, :admin_email)
    end

end
