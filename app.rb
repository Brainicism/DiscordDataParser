require_relative 'lib/messages_analyzer'
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
        @message_analyzer = MessagesAnalyzer.new(messages_path)
    end
    
    def call
        @message_analyzer.call
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