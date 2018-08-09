require_relative '../utils'
class ActivityAnalyzer
    attr_reader :path, :session_processor, :reaction_processor, :game_processor, :voice_processor
    attr_accessor :games
    def initialize(path)
        @path = path
        @session_processor = SessionProcessor.new
        @reaction_processor = ReactionProcessor.new
        @game_processor = GameProcessor.new
        @voice_processor = VoiceProcessor.new
    end

    def call
        raise "Directory doesn't exist\n" if  !File.directory? path
        @start_time = Time.now
        puts 'Begin parsing activity...'
        Dir.foreach(path) do |activity_log| 
            next if activity_log == '.' or activity_log == '..'
            Utils::parse_funky_new_line_json_array("#{path}/#{activity_log}") do |parsed_activity_line|
                event_type = parsed_activity_line['event_type']
                session_processor.process(parsed_activity_line, event_type) if ['session_end', 'session_start', 'app_opened'].include? event_type
                reaction_processor.process(parsed_activity_line, event_type) if ['add_reaction', 'remove_reaction'].include? event_type
                game_processor.process(parsed_activity_line, event_type) if ['launch_game', 'game_opened'].include? event_type
                voice_processor.process(parsed_activity_line) if ['join_voice_channel'].include? event_type
            end
        end
        @end_time = Time.now
        results(output)
    end

    def output 
        [session_processor.output, reaction_processor.output, game_processor.output, voice_processor.output].reduce({}, :merge)
    end

    def results(output)
        output_files = []
        [:games_play_count, :time_by_os, :time_by_location, :time_by_device, :reactions_by_use].each do |type|
            Utils::write_output(output, 'activity' , type) {|output_file| output_files.push(output_file)}
        end
        puts "Finished parsing activity! Took: #{@end_time - @start_time}s"
        puts "Total Sessions: #{output[:total_sessions]}"
        puts "Average session length: #{output[:average_session_length]} minutes" 
        puts "App opened #{output[:total_app_open]} times"
        puts "Total Reactions Added: #{output[:total_reactions_added]}"
        puts "Total Reactions Removed: #{output[:total_reactions_removed]}"
        puts "Total Voice Channels Joined: #{output[:total_voice_channel_connections]}"
        puts "Output files: #{output_files}"
    end

   
end

class VoiceProcessor 
    def initialize
        @total_voice_channel_connections = 0
    end

    def process(activity)
        @total_voice_channel_connections += 1
    end

    def output
        {
            total_voice_channel_connections: @total_voice_channel_connections
        }
    end

end
class GameProcessor 
    def initialize 
        @games = Hash.new(0)
    end

    def process(activity, event_type) 
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

class ReactionProcessor
    def initialize
        @total_reactions_added = 0
        @total_reactions_removed = 0
        @reactions_count_hash = Hash.new(0)
    end

    def process(activity, event_type)
        if event_type == 'add_reaction'
            @total_reactions_added += 1
            @reactions_count_hash[activity['emoji_name']] += 1
        elsif event_type == 'remove_reaction'
            @total_reactions_removed += 1
        end
    end

    def output 
        {
            total_reactions_added: @total_reactions_added,
            total_reactions_removed: @total_reactions_removed,
            reactions_by_use: @reactions_count_hash.sort_by{|reaction, count| count}.reverse
        }
    end
end
class SessionProcessor
    def initialize
        @active_sessions = {}
        @total_session_length = 0
        @total_session_length_by_os = Hash.new(0)
        @total_session_length_by_location = Hash.new(0)
        @total_session_length_by_device = Hash.new(0)
        @total_sessions = 0
        @total_app_open = 0;
    end

    def process(activity, event_type)
        if event_type == 'app_opened'
            @total_app_open += 1
            return
        end
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
            @total_session_length += session_length
            @total_session_length_by_os[activity['os']] += 1
            @total_session_length_by_location["#{activity['city'] || 'unknown'}:#{activity['region_code'] || 'unknown'}:#{activity['country_code'] || 'unknown'}"] += 1
            @total_session_length_by_device[activity['device'] || activity['os'] || 'unknown'] += 1 #no device information for desktop users, default to OS
        end
    end

    def output
        {
            time_by_os: @total_session_length_by_os.sort_by{|os, count| count}.reverse,
            time_by_location: @total_session_length_by_location.sort_by{|location, count| count}.reverse,
            time_by_device: @total_session_length_by_device.sort_by{|device, count| count}.reverse,
            total_sessions: @total_sessions,
            total_app_open: @total_app_open,
            average_session_length: (@total_session_length/@total_sessions).round(2)
        }
    end
    
end