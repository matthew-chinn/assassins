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

        msg += "\nIf you have a ?, ask the admin"

        uri = URI.parse("https://textbelt.com/text")
        res = Net::HTTP.post_form(uri, {
            :number => num,
            :message => msg,
            :key=> "8f2c3a3df3853e507d50fd44cb1ab7082caaecd6z7i5lH3IGzllanDrHngJVqQJ7",
        })
        response = JSON.parse(res.body)

        puts "RES: #{response}"

        if response["success"] == false #error
            puts "RES ERROR: #{response}"
        end

        return response["success"]
    end

    def self.send_email(player, msg, game)
        msg += "\nDont reply to this. If you have questions, ask the admin"
        AlertMailer.alert(player,msg, game).deliver_now
    end

end
