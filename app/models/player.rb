class Player < ActiveRecord::Base
    belongs_to :team
    delegate :game_id, to: :team
end
