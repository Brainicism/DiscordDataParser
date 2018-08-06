class Analyzer
    TIME_OF_DAY_FORMAT = '%H'
    DATE_FORMAT = '%F'
    DAY_OF_WEEK_FORMAT = '%w'

    def initialize 
        @messages_by_date = Hash.new(0)
        @message_by_time_of_day = Hash.new(0)
        @message_by_day_of_week = Hash.new(0)
        @commonly_used_words = Hash.new(0)
        @messages_per_thread = Hash.new
        @total_message_count = 0
        @total_word_count = 0
    end
    def new_data(lines, thread_name)
        @total_message_count += lines.length
        process_messages_by_thread(lines, thread_name)
        lines.each do |line|
            floored_date_time =  floor_hour(line[:date_time])
            process_message_by_time_of_day(floored_date_time)
            process_message_by_day_of_week(floored_date_time)
            process_messages_by_date(floored_date_time)
            process_total_word_count(line[:message])
            process_commonly_used_words(line[:message])
        end
    end

    def output 
        {
            by_date: @messages_by_date.sort_by{|date, count| date}.reverse,
            by_time_of_day: @message_by_time_of_day.sort_by{|hour, count| hour}.map{|hour, count| [convert_24h_to_12h(hour), count]},
            by_day_of_week: @message_by_day_of_week.sort_by{|day, count| day}.map{|day, count| [Date::DAYNAMES[day], count]},
            commonly_used_words: @commonly_used_words.select{|word, count| count > 10}.sort_by{|word, count| count}.reverse,
            per_thread: @messages_per_thread.sort_by{|thread_name, count| count}.reverse,
            average_words_per_message: (@total_word_count.to_f/@total_message_count).round(2),
            total_message_count: @total_message_count
        }
    end
    
    private 
    def process_commonly_used_words(message)
        return if message.nil?
        @commonly_used_words[message.strip.downcase] += 1
    end


    def process_total_word_count(message)
        return if message.nil?
        @total_word_count += message.split(" ").length
    end

    def process_messages_by_date(time)
        @messages_by_date[time.strftime(DATE_FORMAT)] += 1
    end

    def process_messages_by_thread(lines, thread_name)
        @messages_per_thread[thread_name] = lines.length
    end
    def process_message_by_time_of_day(time) 
        @message_by_time_of_day[time.strftime(TIME_OF_DAY_FORMAT)] += 1
    end

    def process_message_by_day_of_week(time) 
        @message_by_day_of_week[time.strftime(DAY_OF_WEEK_FORMAT).to_i] += 1
    end
    def floor_hour(time)
        time - time.sec - 60 * time.min
    end

    def convert_24h_to_12h(hour)
        Time.parse("#{hour}:00").strftime("%l:00 %p")
    end
end