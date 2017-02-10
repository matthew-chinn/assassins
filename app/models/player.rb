class Player < ActiveRecord::Base
    belongs_to :team
    delegate :game_id, to: :team

    #give them a key
    def assign_key!
        key = ""
        if self.name.length > 2
            key += self.name[0..2]
        else
            key += self.name
        end
        key += (self.team_id % 10).to_s
        key += rand(10).to_s

        #avoid duplicates
        while Player.exists?(key: key)
            key += rand(10).to_s
        end

        self.update_attribute(:key ,key)
    end
end
