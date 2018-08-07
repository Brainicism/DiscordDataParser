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

@output_files = []
def write_output(output, type)
    if !output.key? type
        print "Could not find output key: #{type}\n"
        return
    end
    output_file = "#{type.to_s}.csv"
    @output_files.push output_file
    CSV.open(output_file, "w") do |csv|
        output[type].each do |key, value|
            csv << [key, value]
        end
    end
end

begin
    message_index = JSON.parse(File.read("#{MESSAGES_PATH}/index.json"))
rescue JSON::ParserError, Errno::ENOENT
    print "Could not parse #{"#{MESSAGES_PATH}/index.json"}\n"
    return
end

#ignore . .. and index.json
total_threads = Dir.entries(MESSAGES_PATH).size - 3
start_time = Time.now
message_index.each_with_index do |(thread_id, thread_name), index|
    thread_name = thread_name.nil? ? 'unknown_user': thread_name
    print "Progress: #{index + 1}/#{total_threads} (#{thread_name})\n"
    parse_message_file("#{MESSAGES_PATH}/#{thread_id}/messages.csv", thread_name)
end
end_time = Time.now
output = @analyzer.output
system "clear" or system "cls"

[:by_date, :by_time_of_day, :by_day_of_week, :per_thread, :commonly_used_words].each{|type| write_output(output, type)}

print "Output files: #{@output_files}\n"
print "Total Messages: #{output[:total_message_count]}\n"
print "Average words per sentence: #{output[:average_words_per_message]}\n"
print "Average messages per day: #{output[:average_messages_per_day]}\n"
print "Most used word: #{output[:commonly_used_words][0]}\n"
print "Most active thread: #{output[:per_thread][0]}\n"
print "Took: #{end_time - start_time}s\n"