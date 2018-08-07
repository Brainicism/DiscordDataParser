require_relative 'analyzer'
require 'time'
require_relative 'utils'
class DiscordDataParser
    attr_accessor :MESSAGES_PATH
    @@time_zone = Time.now.zone.freeze

    def initialize
        @output_files = []
        @analyzer = Analyzer.new
        if ARGV[0].nil?
            puts "Defaulting to messages directory ./messages..."
            @MESSAGES_PATH = './messages'.freeze
        else
            @MESSAGES_PATH = ARGV[0].freeze
        end
    end

    def call
        raise "Directory doesn't exist\n" if  !File.directory? self.MESSAGES_PATH 
        message_index = Utils::parse_json_from_file("#{self.MESSAGES_PATH}/index.json")
        total_threads = Utils::get_num_of_directories(self.MESSAGES_PATH)
        @start_time = Time.now
        message_index.each_with_index do |(thread_id, thread_name), index|
            thread_name = thread_name.nil? ? 'unknown_user': thread_name
            puts "Progress: #{index + 1}/#{total_threads} (#{thread_name})"
            parse_message_file("#{self.MESSAGES_PATH}/#{thread_id}/messages.csv", thread_name)
        end
        @end_time = Time.now
        system "clear" or system "cls"
        results(@analyzer.output)
    end

    private
    def results(output)
        [:by_date, :by_time_of_day, :by_day_of_week, :per_thread, :commonly_used_words].each do |type|
            Utils::write_output(output, type) {|output_file| @output_files.push(output_file)}
        end
        
        puts "Output files: #{@output_files}"
        puts "Total Messages: #{output[:total_message_count]}"
        puts "Average words per sentence: #{output[:average_words_per_message]}"
        puts "Average messages per day: #{output[:average_messages_per_day]}"
        puts "Most used word: #{output[:commonly_used_words][0]}"
        puts "Most active thread: #{output[:per_thread][0]}"
        puts "Took: #{@end_time - @start_time}s"
    end

    def parse_message_file(file_path, thread_name)
        csv_lines = Utils::read_csv_from_file(file_path)
        csv_lines.shift
        csv_lines = csv_lines.map do |csv_line|
            begin
                {
                    date_time: Time.parse(csv_line[1]) + Time.zone_offset(@@time_zone),
                    message: csv_line[2],
                    attachments: csv_line[3]
                }
            rescue
                puts "Could not parse csv line"
                return {}
            end
        end
        @analyzer.new_data(csv_lines, thread_name)
    end
end

if $PROGRAM_NAME == __FILE__
    begin
        DiscordDataParser.new.call
    rescue => e
        puts "#{e}"
    end
    gets.chomp
end