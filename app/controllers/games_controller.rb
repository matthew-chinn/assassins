class GamesController < ApplicationController
    before_action :check_admin, 
        only: [:show, :add_players, :assign_targets, 
               :life_update, :create_alerts, :send_alerts]
    before_action :redirect_nonadmin, 
        only: [:add_players, :assign_targets, 
               :life_update, :create_alerts, :send_alerts]
    
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
            redirect_to game_path(@created_game, key: @created_game.key)
        end
    end

    def show
        @game = Game.find(params[:id])
        @teams = @game.teams

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
    end

    def signup
        @game = Game.find(params[:id])
        @player = Player.new
    end

    def add_player
        @game = Game.find(params[:id])
        @player = Player.create(player_params)
        if @player.errors.any?
            flash[:danger] = "Error creating player"
            render 'signup'
            return
        end
        redirect_to action: 'show', id: @game.id
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

        redirect_to action: 'show', id: @game.id, key: @key 
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
        if unsuccessful = nil or unsuccessful.count == 0
            flash[:success] = "Sent alerts successfully"
        else
            str = ""
            unsuccessful.each do |p|
                str += " #{p.name}," 
            end
            flash[:error] = "Error sending alerts to #{str}"
        end
        redirect_to action: 'create_alerts', id: @game.id, key: @key
    end

    private
    def game_params 
        params.require(:game).permit(:title, :description, :key)
    end

    def player_params 
        params.require(:player).permit(:name, :contact, :phone, :team_id)
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
