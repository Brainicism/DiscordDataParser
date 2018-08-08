require_relative '../utils'
class ActivityAnalyzer
    attr_reader :path
    attr_accessor :current_session, :total_session_length, :total_sessions, :games
    def initialize(path)
        @path = path
        @active_sessions = {}
        @total_session_length = 0
        @total_sessions = 0
        @games = Hash.new(0)
    end

    def call
        raise "Directory doesn't exist\n" if  !File.directory? path
        Dir.foreach(path) do |activity_log| 
            next if activity_log == '.' or activity_log == '..'
            Utils::parse_funky_new_line_json_array("#{path}/#{activity_log}") do |parsed_activity_line|
                event_type = parsed_activity_line['event_type']
                #process_session(parsed_activity_line, event_type) if ['session_end', 'session_start'].include? event_type
                process_game(parsed_activity_line, event_type) if ['launch_game', 'game_opened'].include? event_type
            end
        end
        #puts "Average session length: #{total_session_length/total_sessions}" 
        results(output)
    end

    def output 
        {
            games_play_count: games.sort_by{|game, count| count}.reverse
        }
    end

    def results(output)
        output_files = []
        [:games_play_count].each do |type|
            Utils::write_output(output, type) {|output_file| output_files.push(output_file)}
        end
        puts "Output files: #{output_files}"
    end

    private
    def process_game(activity, event_type) 
        case event_type
        when 'launch_game'
            game = activity['game']
        when 'game_opened'
            game = activity['game_name']
        end
        games[game] += 1
    end

    #WIP
    def process_session(activity, event_type)
        if event_type == 'session_start'
            @total_sessions += 1
            @active_sessions[activity['session']] ||= {} 
            @active_sessions[activity['session']]['start'] = activity['timestamp']
        elsif event_type == 'session_end'
            @active_sessions[activity['session']] ||= {}
            @active_sessions[activity['session']]['end'] = activity['timestamp']
        end
        if @active_sessions[activity['session']]['start'] && @active_sessions[activity['session']]['end']
            session_start = Time.parse(@active_sessions[activity['session']]['start'])
            session_end = Time.parse(@active_sessions[activity['session']]['end'])
            @active_sessions.delete(activity['session'])

            session_length = ((session_end - session_start)/60).round(2)
            self.total_session_length += session_length
            puts "Session lasted #{session_length}"
        end
    end

end
