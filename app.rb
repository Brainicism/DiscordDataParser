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
        @activity_analyzer = ActivityAnalyzer.new(activity_path)
    end
    
    def call
        @message_analyzer.call
        @activity_analyzer.call
        puts 'Finished!'
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