class Alerter
    def self.send_alerts(game, alive_only, msg, include_assignment)
        teams_hash = game.teams_hash(alive_only)
        #list of people didnt send alert to
        unsuccessful = send_alerts_helper(teams_hash, msg, include_assignment)
    end

    def self.send_email(player, msg)
    end

    private
    def self.send_alerts_helper(teams_hash, message, include_assignment)
        unsuccessful = []
        teams_hash.each do |team, players|
            players.each do |player|
                msg = message.clone
                if include_assignment and player.target_id
                    target = Player.find(player.target_id)
                    msg += "\n#{player.name}, your target is #{target.name}"
                end

                res = true
                if player.phone
                    res = send_text(player,msg)
                else
                    puts "Email Player: #{player.name}, Message: #{msg}"
                    #res = send_email(player,msg)
                end

                if not res
                    unsuccessful << player
                end
            end
        end
        return unsuccessful
    end

    def self.send_text(player, msg)
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

end
