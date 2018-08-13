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

    def fill_messages_by_date
        # TODO: make more efficient
        sorted = @messages_by_date.sort
        Date.parse(sorted.first[0]).upto(Date.parse(sorted.last[0])) do |date|
            date = date.strftime(Utils::DATE_FORMAT)
            found = sorted.find { |data| data[0] == date }
            sorted.push [date, 0] if found.nil?
        end
        sorted = sorted.sort
        @messages_by_date = sorted
    end

    def fill_messages_by_time_of_day
        # TODO: make more efficient
        sorted = @message_by_time_of_day.sort
        0.upto(23).map do |hour|
            hour = hour < 10 ? "0#{hour}" : hour.to_s
            found = sorted.find { |data| data[0] == hour }
            sorted.push [hour, 0] if found.nil?
        end
        sorted = sorted.sort
        @message_by_time_of_day = sorted
    end

    def fill_messages_by_day_of_week
        # TODO: make more efficient
        sorted = @message_by_day_of_week.sort
        0.upto(6).map do |day|
            found = sorted.find { |data| data[0] == day }
            sorted.push [day, 0] if found.nil?
        end
        sorted = sorted.sort
        @message_by_day_of_week = sorted
    end

    def output
        {
            by_date: fill_messages_by_date,
            by_time_of_day: fill_messages_by_time_of_day.map { |hour, count| [Utils::convert_24h_to_12h(hour), count] },
            by_day_of_week: fill_messages_by_day_of_week.map { |day, count| [Date::DAYNAMES[day], count] }
        }
    end
end
