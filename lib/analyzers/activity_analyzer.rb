require_relative '../utils'
class ActivityAnalyzer
    attr_reader :path, :session_processor
    attr_accessor :games
    def initialize(path)
        @path = path
        @games = Hash.new(0)
        @session_processor = SessionProcessor.new
    end

    def call
        raise "Directory doesn't exist\n" if  !File.directory? path
        @start_time = Time.now
        puts 'Begin parsing activity...'
        Dir.foreach(path) do |activity_log| 
            next if activity_log == '.' or activity_log == '..'
            Utils::parse_funky_new_line_json_array("#{path}/#{activity_log}") do |parsed_activity_line|
                event_type = parsed_activity_line['event_type']

                session_processor.process_session(parsed_activity_line, event_type) if ['session_end', 'session_start'].include? event_type
                process_game(parsed_activity_line, event_type) if ['launch_game', 'game_opened'].include? event_type
            end
        end
        @end_time = Time.now
        results(output)
    end

    def output 
        {
            games_play_count: games.sort_by{|game, count| count}.reverse,
            time_by_os: session_processor.total_session_length_by_os.sort_by{|os, count| count}.reverse,
            time_by_location: session_processor.total_session_length_by_location.sort_by{|location, count| count}.reverse,
            time_by_device: session_processor.total_session_length_by_device.sort_by{|device, count| count}.reverse
        }
    end

    def results(output)
        output_files = []
        [:games_play_count, :time_by_os, :time_by_location, :time_by_device].each do |type|
            Utils::write_output(output, 'activity' , type) {|output_file| output_files.push(output_file)}
        end
        puts "Finished parsing activity! Took: #{@end_time - @start_time}s"
        puts "Total Sessions: #{session_processor.total_sessions} | Average session length: #{(session_processor.total_session_length/session_processor.total_sessions).round(2)} minutes" 
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
end

class SessionProcessor
    attr_accessor :current_session, :total_session_length, :total_sessions, :total_session_length_by_os, :total_session_length_by_location, :total_session_length_by_device, :active_sessions
    def initialize
        @active_sessions = {}
        @total_session_length = 0
        @total_session_length_by_os = Hash.new(0)
        @total_session_length_by_location = Hash.new(0)
        @total_session_length_by_device = Hash.new(0)
        @total_sessions = 0
    end

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
            self.total_session_length_by_os[activity['os']] += 1
            self.total_session_length_by_location["#{activity['city'] || 'unknown'}:#{activity['region_code'] || 'unknown'}:#{activity['country_code'] || 'unknown'}"] += 1
            self.total_session_length_by_device[activity['device'] || activity['os'] || 'unknown'] += 1 #no device information for desktop users, default to OS
        end
    end
end