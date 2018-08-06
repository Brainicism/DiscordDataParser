require 'json'
require 'csv'
require './analyzer'
require 'time'
@analyzer = Analyzer.new
@time_zone = Time.now.zone.freeze

if ARGV[0].nil?
    print "Defaulting to messages directory ./messages...\n"
    MESSAGES_PATH = './messages'.freeze
else
    MESSAGES_PATH = ARGV[0].freeze
end

if !File.directory? MESSAGES_PATH
    print "Directory doesn't exist\n"
    return
end

def parse_message_file(file_path, thread_name)
    csv_lines = CSV.read(file_path)
    csv_lines.shift
    csv_lines = csv_lines.map do |csv_line|
        begin
            {
                date_time: Time.parse(csv_line[1]) + Time.zone_offset(@time_zone),
                message: csv_line[2],
                attachments: csv_line[3]
            }
        rescue
            print "Could not parse csv line\n"
            return {}
        end
    end
    @analyzer.new_data(csv_lines, thread_name)
end

def write_output(type)
    CSV.open("#{type.to_s}.csv", "w") do |csv|
        @analyzer.output[type].each do |key, value|
            csv << [key, value]
        end
    end
end

begin
    message_index = JSON.parse(File.read("#{MESSAGES_PATH}/index.json"))
rescue JSON::ParserError, Errno::ENOENT => e
    print "Could not parse #{"#{MESSAGES_PATH}/index.json"}\n"
    return
end

total_threads = Dir.entries(MESSAGES_PATH).size
message_index.each_with_index do |(thread_id, thread_name), index|
    print "Progress: #{index}/#{total_threads}\n"
    processed_data = parse_message_file("#{MESSAGES_PATH}/#{thread_id}/messages.csv", thread_name.nil? ? 'unknown_user' : thread_name )
end

write_output(:by_date)
write_output(:by_time_of_day)
write_output(:by_day_of_week)
write_output(:per_thread)
system "clear" or system "cls"
print "Total Messages: #{@analyzer.output[:total_message_count]}\n"
print "Average words per sentence: #{@analyzer.output[:average_words_per_message]}\n"