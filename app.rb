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
        @activity_analyzer = ActivityAnalyzer.new(activity_path, @params)
        @message_analyzer = MessagesAnalyzer.new(messages_path, @params, @activity_analyzer)
        @account_analyzer = AccountAnalyzer.new(account_path, @params)
    end

    def call
        if @params[:rebuild_binary]
            exec 'ocra app.rb public/ --output bin/app.exe --gem-all'
            puts 'Binary Updated'
            return
        end

        generate_output_directory
        if @params[:verify_events] || @params[:update_events]
            analyzers = [@activity_analyzer]
        else
            analyzers = [@activity_analyzer, @message_analyzer, @account_analyzer]
        end
        final_output = analyzers.map(&:call).each_with_object(output_files: [], misc_data: {}, output_data: {}) do |output, total|
            total[:output_files] += output[:output_files] || []
            total[:misc_data].merge! (output[:misc_data] || {})
            total[:output_data].merge!(output[:output_data] || {})
        end
        final_output[:output_data][:utc_offset] = Utils.zone_offset_to_utc_offset(Time.zone_offset(Utils.timezone(@params)))

        FileUtils.cp(final_output[:misc_data][:avatar_path], './output/visualizations/avatar.png')
        ResultRenderer.new(final_output, @activity_analyzer.output_available).render
        Utils.open_html_graphs
    end

    def generate_output_directory
        FileUtils.mkdir_p './output/visualizations'
        FileUtils.cp(File.expand_path('public/index.css', __dir__), './output/visualizations/index.css')
        FileUtils.cp(File.expand_path('public/favicon.ico', __dir__), './output/visualizations/favicon.ico')
    end
end

if $PROGRAM_NAME == __FILE__
    begin
        DiscordDataParser.new.call
    rescue StandardError => e
        puts e.to_s
    end
end
