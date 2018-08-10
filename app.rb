require_relative 'lib/analyzers/messages_analyzer'
require_relative 'lib/analyzers/activity_analyzer'
require_relative 'lib/utils'
require 'time'

class DiscordDataParser
    def initialize
        if ARGV[0].nil?
            puts "Defaulting to data directory ./data..."
            data_path = './data'.freeze
        else
            data_path = ARGV[0].freeze
        end
        messages_path = "#{data_path}/messages"
        activity_path = "#{data_path}/activity/analytics"
        @message_analyzer = MessagesAnalyzer.new(messages_path)
        activity_analyzer_params = {}
        activity_analyzer_params[:verify_events] = true if ARGV.include? '--verify-events'
        activity_analyzer_params[:update_events] = true if ARGV.include? '--update-events'
        @activity_analyzer = ActivityAnalyzer.new(activity_path, activity_analyzer_params)
    end
    
    def call
        final_output = [@message_analyzer.call, @activity_analyzer.call].reduce({output_files: [], output_strings: []}) do |total, output|
            total[:output_files] += output[:output_files]
            total[:output_strings] += output[:output_strings]
            total
        end
        system "clear" or system "cls"
        puts "Files saved: [#{final_output[:output_files].map{|file| "\"#{file}\""  }.join(", ")}]"
        puts final_output[:output_strings].join("\n")
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