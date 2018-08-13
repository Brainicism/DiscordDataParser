require_relative 'lib/analyzers/messages_analyzer'
require_relative 'lib/analyzers/activity_analyzer'
require_relative 'lib/utils'
require_relative 'lib/arg_parser'
require_relative 'lib/result_renderer'
require 'time'
require 'erb'
class DiscordDataParser
    def initialize
        @params = ArgParser.parse(ARGV)
        if @params[:data_path].nil?
            puts 'Defaulting to data directory ./'
            data_path = './'.freeze
        else
            data_path = @params[:data_path]
        end
        messages_path      = "#{data_path}/messages"
        activity_path      = "#{data_path}/activity/analytics"
        @message_analyzer  = MessagesAnalyzer.new(messages_path, @params)
        @activity_analyzer = ActivityAnalyzer.new(activity_path, @params)
    end

    def call
        if @params[:verify_events] || @params[:update_events]
            analyzers = [@activity_analyzer]
        else
            analyzers = [@message_analyzer, @activity_analyzer]
        end
        final_output = analyzers.map(&:call).each_with_object(output_files: [], output_strings: [], output_raw: {}) do |output, total|
            total[:output_files]   += output[:output_files]
            total[:output_strings] += output[:output_strings]
            total[:output_raw].merge!(output[:output_raw])
        end
        puts final_output[:output_raw]
        ResultRenderer.new(final_output[:output_raw]).render

        system('clear') || system('cls')
        puts "Files saved: [#{final_output[:output_files].map { |file| "\"#{file}\"" }.join(', ')}]"
        puts 'Prettified message files saved: output/prettified/messages'
        puts final_output[:output_strings].join("\n")
        puts 'Done!'

        Utils.open_html_graphs
    end
end

if $PROGRAM_NAME == __FILE__
    begin
        DiscordDataParser.new.call
    rescue StandardError => e
        puts e.to_s
    end
    gets.chomp
end
