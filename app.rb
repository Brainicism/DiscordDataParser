require_relative 'src/analyzers/messages_analyzer'
require_relative 'src/analyzers/activity_analyzer'
require_relative 'src/analyzers/account_analyzer'
require_relative 'src/utils'
require_relative 'src/arg_parser'
require_relative 'src/result_renderer'
require 'time'
require 'erb'
class DiscordDataParser
    def initialize
        Utils.version_check
        @params = ArgParser.parse(ARGV)
        if defined?(Ocra)
            @params[:quick_run] = true # ocra only runs app to check for dependencies, no need for full parse
            data_path = './data'.freeze
        elsif @params[:data_path].nil?
            puts 'Defaulting to data directory ./'
            data_path = './'.freeze
        else
            data_path = @params[:data_path]
        end
        messages_path = "#{data_path}/messages"
        activity_path = "#{data_path}/activity/analytics"
        account_path = "#{data_path}/account"
        @message_analyzer = MessagesAnalyzer.new(messages_path, @params)
        @activity_analyzer = ActivityAnalyzer.new(activity_path, @params)
        @account_analyzer = AccountAnalyzer.new(account_path, @params)
    end

    def call
        if @params[:rebuild_binary]
            exec 'ocra app.rb public/index.erb --output bin/app.exe'
            puts 'Binary Updated'
            return
        end

        generate_output_directory
        
        if @params[:verify_events] || @params[:update_events]
            analyzers = [@activity_analyzer]
        else
            analyzers = [@message_analyzer, @activity_analyzer, @account_analyzer]
        end
        final_output = analyzers.map(&:call).each_with_object(output_files: [], output_strings: [], output_raw: {}) do |output, total|
            total[:output_files] += output[:output_files]
            total[:output_strings] += output[:output_strings]
            total[:output_raw].merge!(output[:output_raw])
        end

        #oh god why
        final_output[:output_raw][:utc_offset] = Utils.zone_offset_to_utc_offset(Time.zone_offset(Utils.timezone(@params)))
        ResultRenderer.new(final_output[:output_raw]).render

        system('clear') || system('cls')
        puts "Files saved: [#{final_output[:output_files].map { |file| "\"#{file}\"" }.join(', ')}]"
        puts 'Prettified message files saved: output/prettified/messages'
        puts final_output[:output_strings].join("\n")
        puts 'Done!'

        Utils.open_html_graphs
    end

    def generate_output_directory
        FileUtils.mkdir_p './output/visualizations'
        FileUtils.cp('./public/index.css', './output/visualizations/index.css')
    end
end

if $PROGRAM_NAME == __FILE__
    begin
        DiscordDataParser.new.call
        gets.chomp unless defined?(Ocra)
    rescue StandardError => e
        puts e.to_s
    end
end
