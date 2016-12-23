class PagesController < ApplicationController
    def home
    end

    def about
        @title = "About"
    end

    def redirect
        g = Game.find_by(key: params[:key])
        if not g
            flash[:danger] = "Key not found"
            redirect_to root_path
            return
        end

        redirect_to game_path(id: g.id, key: params[:key])
    end
end
