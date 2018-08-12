require 'json'
require 'csv'
require 'fileutils'
class Utils
    OUTPUT_PATH = './output'
    TIME_FORMAT_24H = '%l:00 %p'
    TIME_OF_DAY_FORMAT = '%H'
    DATE_FORMAT = '%F'
    DAY_OF_WEEK_FORMAT = '%w'
    TIMEZONE = Time.now.zone.freeze
	HTML_PATH = './output/index.html'
    class << self
        def parse_funky_new_line_json_array(path)
            File.foreach(path) do |json_line|
                yield JSON.parse(json_line)
            end
        end

        def parse_json_from_file(path)
            begin
                JSON.parse(File.read(path))
            rescue JSON::ParserError, Errno::ENOENT => e
                raise "Could not parse #{path}. #{e.to_s[0..50]}\n"
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

        def get_num_of_files(path)
            Dir.entries(path).select {|entry| File.file? File.join(path, entry) and !(entry =='.' || entry == '..') }.length
        end

        def write_output_txt(output, directory, file_name)
            output_file = "#{file_name}.txt"
            dir_path = "#{OUTPUT_PATH}/#{directory}"
            FileUtils.mkdir_p dir_path
            File.open("#{dir_path}/#{output_file}", 'w') do |file| 
                file.write(output)
            end
        end
    
        def write_output_csv(output, directory, type)
            if !output.key? type
                puts "Could not find output key: #{type}"
                return
            end
            output_file = "#{type.to_s}.csv"
            dir_path = "#{OUTPUT_PATH}/#{directory}"
            FileUtils.mkdir_p dir_path
            CSV.open("#{dir_path}/#{output_file}", "w") do |csv|
                output[type].each do |key, value|
                    csv << [key, value]
                end
            end
            yield "#{directory}/#{output_file}"
        end

		module OS
			def OS.windows?
				(/"cygwin"|"mswin"|"mingw"|"bccwin"|"wince"|"emx"/ =~ RUBY_PLATFORM) != nil
			end

			def OS.mac?
				(/darwin/ =~ RUBY_PLATFORM) != nil
			end

			def OS.unix?
				!OS.windows?
			end

			def OS.linux?
				OS.unix? and not OS.mac?
			end
		end

		def open_html_graphs()
			if OS.windows?
				`explorer file://#{HTML_PATH}`
			elsif OS.mac?
				`open #{HTML_PATH}`
			elsif OS.unix? || OS.linux?
				`xdg-open #{HTML_PATH}`
			end
		end
    end
end
