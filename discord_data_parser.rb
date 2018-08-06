require 'json'
require 'csv'
require './analyzer'
require 'time'
@analyzer = Analyzer.new
@time_zone = Time.now.zone.freeze
MESSAGES_PATH = './messages'.freeze
def parse_csv(file_path, thread_name)
    lines = CSV.read(file_path)
    lines.shift
    lines = lines.map do |line|
        {
            date_time: Time.parse(line[1]) + Time.zone_offset(@time_zone),
            message: line[2],
            attachments: line[3]
        }
    end
    @analyzer.new_data(lines, thread_name)
end

def write_output(type)
    CSV.open("#{type.to_s}.csv", "w") do |csv|
        @analyzer.output[type].each do |key, value|
            csv << [key, value]
        end
    end
end

message_index = JSON.parse(File.read("#{MESSAGES_PATH}/index.json"))
total_messages = 0
message_index.each do |thread_id, thread_name|
    lines = parse_csv("#{MESSAGES_PATH}/#{thread_id}/messages.csv", thread_name.nil? ? 'unknown_user' : thread_name )
    total_messages = total_messages + lines.length
end

write_output(:by_date)
write_output(:by_time_of_day)
write_output(:by_day_of_week)
write_output(:per_thread)
print "Total Messages: #{total_messages}"