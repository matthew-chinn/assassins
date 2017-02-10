class GamesController < ApplicationController
    before_action :check_admin, 
        only: [:show, :add_players, :assign_targets, 
               :life_update, :create_alerts, :send_alerts, :edit_player,
               :save_edit_player, :merge_games]
    before_action :redirect_nonadmin, 
        only: [:add_players, :assign_targets, 
               :life_update, :create_alerts, :send_alerts, :edit_player,
               :save_edit_player, :merge_games ]
    
    def new
        @title = "Create Game"
        @new_game = Game.new
    end

    def edit
        @key = params[:key]
        @game = Game.find(params[:id])
    end

    def update
        @game = Game.find(params[:id])
        @game.update!(game_params)
        redirect_to game_path(id: params[:id], key: params[:key])
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
            redirect_to game_path(@created_game, key: @created_game.key)
        end
    end

    def show
        @game = Game.find(params[:id])
        @teams = @game.teams
        @title = "#{@game.title}"

        #leaderboard
        @leaders = []
        str = ""
        @teams.each do |team|
            players = Player.where("team_id = ? AND kills > ?
                                   AND alive = ?",
                                 team.id, 0, true)
            if players.count > 0
                @leaders += players.all
            end
        end
        if @leaders.count > 1
            @leaders = @leaders.sort! { |x,y| y.kills <=> x.kills }
            @leaders = @leaders.take(5)
        end

    end

    def index
        @games = Game.all
        @title = "View Games"
    end

    def signup
        @game = Game.find(params[:id])
        @player = Player.new
        @title = "New Player"
        @action = "Submit"
        @url = add_player_path(@game)
    end

    def edit_player
        @game = Game.find(params[:id])
        @player = Player.find(params[:player_id])
        @action = "Save"
        @title = "Edit #{@player.name}"
        @url = save_edit_player_path(id: @game.id, player_id: @player.id)
        render 'signup'
    end

    def delete_player
        @player = Player.find(params[:id])
        if Player.exists?(target_id: @player.id)
            p = Player.find_by(target_id: @player.id)
            p.target_id = nil
        end
        @player.destroy
        redirect_to game_path(params[:game_id])
    end

    def view_player
        if request.get?
            redirect_to root_path
            return
        end
        if Player.exists?(key: params[:key])
            @player = Player.find_by(key: params[:key])
            @target = Player.exists?(id: @player.target_id) ? 
                        Player.find(@player.target_id) : nil
            return
        end
        flash[:error] = "Player with that key doesn't exist"
        redirect_to root_path
    end

    def save_edit_player
        @game = Game.find(params[:id])
        p = Player.find(params[:player_id])
        p.update_attributes(player_params)
        @game.update_time
        redirect_to action: 'show', id: @game.id, key: @key
    end

    def add_player
        @game = Game.find(params[:id])

        @player = Player.create(player_params)
        if @player.errors.any?
            flash[:danger] = "Error creating player"
            render 'signup'
            return
        end
        @player.assign_key 

        @game.update_time
        redirect_to action: 'show', id: @game.id, key: @key
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
            @game.update_time
        end

        redirect_to action: 'show', id: @game.id, key: @key 
    end

    #Assign all the targets then render page to view
    def assign_targets
        @game = Game.find(params[:id])
        
        teams = @game.assign_targets(params[:type])
        if not teams
            #if unsuccessful, redirect to show page
            flash[:danger] = "Error assigning targets"
            redirect_to action: 'show', id: @game.id, key: @key
            return
        end

        @game.update_time
        redirect_to action: 'show', id: @game.id, key: @key
    end

    def life_update
        action = params[:act]
        game = Game.find(params[:id])

        if action == "suicide"
            victim = Player.find(params[:player])
            killer = Player.find_by(target_id: victim.id)

            if killer
                killer.update_attributes(target_id: victim.target_id) #assign killer their target
            end
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
        elsif action == "revive_all"
            teams = game.teams
            teams.each do |team|
               Player.where(team_id: team.id, alive: false).update_all(alive: true)
            end
        end
        @game.update_time
        redirect_to action: 'show', id: game.id, key: @key
    end

    def create_alerts
        @game = Game.find(params[:id])
    end

    def send_alerts
        @game = Game.find(params[:id])
        alive_only = params[:alive_only]
        msg = params[:message]
        include_assignment = params[:include_assignment]
        #list of players that did not get sent updates
        unsuccessful = Alerter.send_alerts(@game, alive_only, msg, include_assignment)
        if unsuccessful == nil or unsuccessful.count == 0
            flash[:success] = "Sent alerts successfully"
        else
            str = ""
            unsuccessful.each do |p|
                str += " #{p.name}," 
            end
            flash[:error] = "Error sending alerts to #{str}"
        end
        @game.update_time
        redirect_to action: 'create_alerts', id: @game.id, key: @key
    end

    def merge_games
        game = Game.find(params[:id])
        other_game = Game.find_by(key: params[:other_key])
        if not other_game
            flash[:error] = "No game found with that key"
            redirect_to action: 'show', id: game.id, key: @key
            return
        end
        game.merge_with(other_game)
        flash[:success] = "Merged successfully"
        redirect_to action: 'show', id: game.id, key: @key
    end

    private
    def game_params 
        params.require(:game).permit(:title, :description, :key, :admin_email)
    end

    def player_params 
        params.require(:player).permit(:name, :contact, :phone, :team_id)
    end

    def create_teams(text, game)
        toks = text.split(',')
        toks.each do |t|
            game.teams << Team.create(name: t.strip, game_id: game.id)
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


    def check_admin
        if not params[:key]
            @admin = false
        else
            @game = Game.find(params[:id])
            @admin = @game.key == params[:key]
            @key = params[:key]
        end
    end

    def redirect_nonadmin
        if not @admin
            redirect_to action: 'show', id: @game.id
        end
    end

end
