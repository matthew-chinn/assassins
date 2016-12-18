class Team < ActiveRecord::Base
    has_many :players, dependent: :destroy
    
    def total_kills
        return self.players.inject(0) { 
            |sum,p| sum + p.kills }
    end

    def total_remaining
        return self.players.inject(0) { 
            |sum,p| p.alive ? sum + 1 : sum }
    end
end
