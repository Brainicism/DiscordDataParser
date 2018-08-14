require 'json'
require 'csv'
require 'fileutils'
require_relative 'user_os.rb'

class Utils
    OUTPUT_PATH = './output'.freeze
    TIME_FORMAT_24H = '%l:00 %p'.freeze
    TIME_OF_DAY_FORMAT = '%H'.freeze
    DATE_FORMAT = '%F'.freeze
    DAY_OF_WEEK_FORMAT = '%w'.freeze
    TIMEZONE = Time.now.zone.freeze
    HTML_PATH = 'output/index.html'.freeze

    class << self
        def parse_funky_new_line_json_array(path)
            File.foreach(path) do |json_line|
                yield JSON.parse(json_line)
            end
        end

        def parse_json_from_file(path)
            JSON.parse(File.read(path))
        rescue JSON::ParserError, Errno::ENOENT => e
            raise "Could not parse #{path}. #{e.to_s[0..50]}\n"
        end

        def read_csv_from_file(path)
            CSV.read(path)
        rescue Errno::ENOENT
            raise "Could not parse #{path}\n"
        end

        def convert_24h_to_12h(hour)
            Time.parse("#{hour}:00").strftime(TIME_FORMAT_24H)
        end

        def get_num_of_directories(path)
            Dir.entries(path).select { |entry| (File.directory? File.join(path, entry)) && !(['.', '..'].include? entry) }.length
        end

        def get_num_of_files(path)
            Dir.entries(path).select { |entry| (File.file? File.join(path, entry)) && !(['.', '..'].include? entry) }.length
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
            unless output.key? type
                puts "Could not find output key: #{type}"
                return
            end
            output_file = "#{type}.csv"
            dir_path = "#{OUTPUT_PATH}/#{directory}"
            FileUtils.mkdir_p dir_path
            CSV.open("#{dir_path}/#{output_file}", 'w') do |csv|
                output[type].each do |key, value|
                    csv << [key, value]
                end
            end
            yield "#{directory}/#{output_file}"
        end

        def open_html_graphs
            if OS.windows?
                `explorer file://#{File.expand_path("#{HTML_PATH}", File.dirname(ENV["OCRA_EXECUTABLE"]))}` if ENV["OCRA_EXECUTABLE"]
                `explorer file://#{File.expand_path("../#{HTML_PATH}", File.dirname(__FILE__))}` unless ENV["OCRA_EXECUTABLE"]
            elsif OS.mac?
                `open #{HTML_PATH}`
            elsif OS.unix? || OS.linux?
                `xdg-open #{HTML_PATH}`
            end
        end

        def word_is_mention_or_emoji(word)
            word =~ /<:[a-zA-Z0-9]+:[0-9]+>/ || word =~ /<@![0-9]+>/ || word =~ /<@[0-9]+>/
        end
    end
end
