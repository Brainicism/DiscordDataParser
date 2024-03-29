require_relative '../utils'
require_relative '../processors/message_content_processor'
require_relative '../processors/message_by_date_processor'
require_relative '../processors/message_prettifier_processor'
class MessagesAnalyzer
    attr_reader :path, :message_by_content_processor, :message_by_date_processor, :message_prettifier_processor

    def initialize(path, params, activity_analyzer)
        @path = path
        @params = params
        @message_by_content_processor = MessageByContentProcessor.new(params)
        @message_by_date_processor = MessageByDateProcessor.new
        @message_prettifier_processor = MessagePrettifierProcessor.new
        @activity_analyzer = activity_analyzer
    end

    def call
        raise "#{path} doesn't exist\n" unless File.directory? path
        message_index = Utils.parse_json_from_file("#{path}/index.json")
        @start_time = Time.now
        puts 'Begin parsing messages...'
        if @params[:thread_id]
            message_index = message_index.select { |thread_id| thread_id == @params[:thread_id] }
            @specified_thread_name = message_index[@params[:thread_id]] || 'unknown'
            raise "Couldn't find thread id: #{@params[:thread_id]}" if message_index.empty?
        end
        total_threads = message_index.length
        @timezone_offsets_by_day = @activity_analyzer.timezone_offsets_by_day || {}
        message_index.each_with_index do |(thread_id, thread_name), index|
            break if @params[:quick_run] == true && index > 50
            thread_name = thread_name.nil? ? 'unknown_user' : thread_name
            puts "Progress: #{index + 1}/#{total_threads} (#{thread_name})"
            parse_message_file("#{path}/#{thread_id}/messages.csv", thread_name, thread_id)
        end
        @end_time = Time.now
        puts 'Finished parsing messages...'
        results(output)
    end

    def results(output)
        output_files = []
        output[:specified_thread_name] = @specified_thread_name if @specified_thread_name
        [:by_date, :by_time_of_day, :by_day_of_week, :per_thread, :commonly_used_messages, :commonly_used_words].each do |type|
            Utils.write_output_csv(output, 'analyzed/messages', type) { |output_file| output_files.push(output_file) }
        end
        {
            output_files: output_files,
            misc_data: {
                messages: {
                    analysis_duration: (@end_time - @start_time).round(1),
                    total_message_count: output[:total_message_count],
                    average_words_per_message: output[:average_words_per_message],
                    average_messages_per_day: output[:average_messages_per_day],
                }
            },
            output_data: output
        }
    end

    def output
        [message_by_date_processor.output, message_by_content_processor.output(message_by_date_processor.output[:by_date].length)].reduce({}, :merge)
    end

    private

    def processors
        [message_by_content_processor, message_by_date_processor]
    end

    def processors_by_thread
        [message_prettifier_processor, message_by_content_processor]
    end

    def parse_message_file(file_path, thread_name, thread_id)
        csv_lines = Utils.read_csv_from_file(file_path)
        csv_lines.shift
        begin
            csv_lines = csv_lines.map do |csv_line|
                parsed_time = Time.parse(csv_line[:timestamp])
                if @params[:normalize_time] == false
                    timezone_offset = Time.zone_offset(Utils.timezone(@params))
                else
                    timezone_offset = @timezone_offsets_by_day[parsed_time.strftime(Utils::DATE_FORMAT)] || Time.zone_offset(Utils.timezone(@params))
                end
                raise 'Invalid timezone' unless timezone_offset
                {
                    date_time: parsed_time.utc + timezone_offset,
                    message: csv_line[:contents],
                    attachments: csv_line[:attachments]
                }
            end
        rescue StandardError => e
            puts "Could not parse csv line #{e}"
            return {}
        end
        new_data(csv_lines, thread_name, thread_id)
    end

    def new_data(lines, thread_name, thread_id)
        # discord backup only has complete data for past 6 months
        months = @params[:months_look_back] ? @params[:months_look_back].to_i : 6
        lines = lines.select{|line| line[:date_time].to_date > Date.today.prev_month(months) }
        processors_by_thread.each { |processor| processor.process_messages_by_thread(lines, thread_name, thread_id) }
        lines.each do |line|
            processors.each { |processor| processor.process(line) }
        end
    end
end
