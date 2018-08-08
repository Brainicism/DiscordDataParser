require_relative '../utils'
class MessagesAnalyzer
    attr_reader :messages_by_date, :message_by_time_of_day, :message_by_day_of_week, :commonly_used_words, :messages_per_thread, :path
    attr_accessor :total_message_count, :total_word_count
    TIME_OF_DAY_FORMAT = '%H'
    DATE_FORMAT = '%F'
    DAY_OF_WEEK_FORMAT = '%w'

    def initialize(path)
        @path = path
        @messages_by_date = Hash.new(0)
        @message_by_time_of_day = Hash.new(0)
        @message_by_day_of_week = Hash.new(0)
        @commonly_used_words = Hash.new(0)
        @messages_per_thread = Hash.new
        @total_message_count = 0
        @total_word_count = 0
    end

    def call
        raise "Directory doesn't exist\n" if  !File.directory? path
        message_index = Utils::parse_json_from_file("#{path}/index.json")
        total_threads = Utils::get_num_of_directories(path)
        @start_time = Time.now
        message_index.each_with_index do |(thread_id, thread_name), index|
            thread_name = thread_name.nil? ? 'unknown_user': thread_name
            puts "Progress: #{index + 1}/#{total_threads} (#{thread_name})"
            parse_message_file("#{path}/#{thread_id}/messages.csv", thread_name)
        end
        @end_time = Time.now
        system "clear" or system "cls"
        results(output)
    end
    
    private 
    def output 
        {
            by_date: messages_by_date.sort_by{|date, count| date}.reverse,
            by_time_of_day: message_by_time_of_day.sort_by{|hour, count| hour}.map{|hour, count| [Utils::convert_24h_to_12h(hour), count]},
            by_day_of_week: message_by_day_of_week.sort_by{|day, count| day}.map{|day, count| [Date::DAYNAMES[day], count]},
            commonly_used_words: commonly_used_words.select{|word, count| count >= 10}.sort_by{|word, count| count}.reverse,
            per_thread: messages_per_thread.sort_by{|thread_name, count| count}.reverse,
            average_words_per_message: (total_word_count.to_f/total_message_count).round(2),
            average_messages_per_day: (total_message_count.to_f/messages_by_date.keys.length).round(2),
            total_message_count: total_message_count
        }
    end

    def results(output)
        output_files = []
        [:by_date, :by_time_of_day, :by_day_of_week, :per_thread, :commonly_used_words].each do |type|
            Utils::write_output(output, type) {|output_file| output_files.push(output_file)}
        end
        
        puts "Output files: #{output_files}"
        puts "Total Messages: #{output[:total_message_count]}"
        puts "Average words per sentence: #{output[:average_words_per_message]}"
        puts "Average messages per day: #{output[:average_messages_per_day]}"
        puts "Most used word: #{output[:commonly_used_words][0]}"
        puts "Most active thread: #{output[:per_thread][0]}"
        puts "Took: #{@end_time - @start_time}s"
    end

    def new_data(lines, thread_name)
        self.total_message_count += lines.length
        process_messages_by_thread(lines, thread_name)
        lines.each do |line|
            process_message_by_time_of_day(line[:date_time])
            process_message_by_day_of_week(line[:date_time])
            process_messages_by_date(line[:date_time])
            process_total_word_count(line[:message])
            process_commonly_used_words(line[:message])
        end
    end

    def parse_message_file(file_path, thread_name)
        csv_lines = Utils::read_csv_from_file(file_path)
        csv_lines.shift
        csv_lines = csv_lines.map do |csv_line|
            begin
                {
                    date_time: Time.parse(csv_line[1]) + Time.zone_offset(Utils::TIMEZONE),
                    message: csv_line[2],
                    attachments: csv_line[3]
                }
            rescue
                puts "Could not parse csv line"
                return {}
            end
        end
        new_data(csv_lines, thread_name)
    end

    def process_commonly_used_words(message)
        return if message.nil?
        commonly_used_words[message.strip.downcase] += 1
    end

    def process_total_word_count(message)
        return if message.nil?
        self.total_word_count += message.split(" ").length
    end

    def process_messages_by_date(time)
        messages_by_date[time.strftime(DATE_FORMAT)] += 1
    end

    def process_messages_by_thread(lines, thread_name)
        messages_per_thread[thread_name] = lines.length
    end
    def process_message_by_time_of_day(time) 
        message_by_time_of_day[time.strftime(TIME_OF_DAY_FORMAT)] += 1
    end

    def process_message_by_day_of_week(time) 
        message_by_day_of_week[time.strftime(DAY_OF_WEEK_FORMAT).to_i] += 1
    end
end