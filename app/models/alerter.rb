class Alerter
    def self.send_alerts(game, alive_only, msg, include_assignment)
        teams_hash = game.teams_hash(alive_only)
        #list of people didnt send alert to
        unsuccessful = send_alerts_helper(teams_hash, msg, include_assignment, game)
        return unsuccessful
    end

    private
    def self.send_alerts_helper(teams_hash, message, include_assignment, game)
        unsuccessful = []
        teams_hash.each do |team, players|
            players.each do |player|
                if not player.contact or player.contact.empty?
                    unsuccessful << player
                    next
                end

                msg = message.clone
                if player.alive and include_assignment and player.target_id
                    target = Player.find(player.target_id)
                    msg += "\n#{player.name}, your target is #{target.name}"
                end

                if player.phone
                    res = send_text(player,msg)
                else
                    res = send_email(player,msg, game)
                end

                if not res
                    unsuccessful << player
                end
            end
        end
        return unsuccessful
    end

    def self.send_text(player, msg)
        if Rails.env.development?
            puts "Send text: #{player.name}, #{msg}"
            return true
        end

        phone = Phonelib.parse player.contact
        num = phone.sanitized

        msg += "\nDont reply to this. If you have questions, ask the admin"

        cmd = "curl -X POST http://textbelt.com/text \ "
        cmd += "-d number=#{num}\ "
        cmd += "-d \message='#{msg}'"
        puts cmd

        res = system(cmd)
        return res
    end

    def self.send_email(player, msg, game)
        msg += "\nDont reply to this. If you have questions, ask the admin"
        AlertMailer.alert(player,msg, game).deliver_now
    end

end
