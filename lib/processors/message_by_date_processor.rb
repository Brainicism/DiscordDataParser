class MessageByDateProcessor 
    attr_reader :messages_by_date
    def initialize 
        @messages_by_date = Hash.new(0)
        @message_by_time_of_day = Hash.new(0)
        @message_by_day_of_week = Hash.new(0)
    end

    def process(line)
        process_message_by_time_of_day(line[:date_time])
        process_message_by_day_of_week(line[:date_time])
        process_messages_by_date(line[:date_time])
    end

    def process_messages_by_date(time)
        @messages_by_date[time.strftime(Utils::DATE_FORMAT)] += 1
    end

    def process_message_by_time_of_day(time) 
        @message_by_time_of_day[time.strftime(Utils::TIME_OF_DAY_FORMAT)] += 1
    end

    def process_message_by_day_of_week(time) 
        @message_by_day_of_week[time.strftime(Utils::DAY_OF_WEEK_FORMAT).to_i] += 1
    end

    def output
        {
            by_date: @messages_by_date.sort_by{|date, count| date}.reverse,
            by_time_of_day: @message_by_time_of_day.sort_by{|hour, count| hour}.map{|hour, count| [Utils::convert_24h_to_12h(hour), count]},
            by_day_of_week: @message_by_day_of_week.sort_by{|day, count| day}.map{|day, count| [Date::DAYNAMES[day], count]},
        }
    end
end