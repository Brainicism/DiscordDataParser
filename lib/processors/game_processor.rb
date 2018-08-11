class GameProcessor 
    def initialize 
        @games = Hash.new(0)
    end

    def process(activity, event_type) 
        return unless ['launch_game', 'game_opened'].include? event_type
        case event_type
        when 'launch_game'
            game = activity['game']
        when 'game_opened'
            game = activity['game_name']
        end
        @games[game] += 1
    end

    def output
        {
            games_play_count: @games.sort_by{|game, count| count}.reverse,
        }
    end
end