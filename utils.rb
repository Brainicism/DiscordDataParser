require 'json'
require 'csv'
class Utils
    TIME_FORMAT_24H = '%l:00 %p'
    class << self
        def parse_json_from_file(path)
            begin
                JSON.parse(File.read(path))
            rescue JSON::ParserError, Errno::ENOENT
                raise "Could not parse #{path}\n"
            end
        end
    
        def read_csv_from_file(path)
            begin
                CSV.read(path)
            rescue Errno::ENOENT
                raise "Could not parse #{path}\n"
            end
        end
    
        def convert_24h_to_12h(hour)
            Time.parse("#{hour}:00").strftime(TIME_FORMAT_24H)
        end
    
        def get_num_of_directories(path)
            Dir.entries(path).select {|entry| File.directory? File.join(path, entry) and !(entry =='.' || entry == '..') }.length
        end

        def write_output(output, type)
            if !output.key? type
                puts "Could not find output key: #{type}"
                return
            end
            output_file = "#{type.to_s}.csv"
            CSV.open(output_file, "w") do |csv|
                output[type].each do |key, value|
                    csv << [key, value]
                end
            end
            yield output_file
        end
    end
end