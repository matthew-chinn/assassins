class AlertMailer < ApplicationMailer
    def alert(player, msg, game)
        @player = player
        @msg = msg
        @game = game
        mail(to: player.contact, subject: "#{game.title} Update",
             from: game.admin_email)
    end
end
