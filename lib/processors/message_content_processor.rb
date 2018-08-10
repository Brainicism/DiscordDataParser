class MessageByContentProcessor
    def initialize
        @commonly_used_words = Hash.new(0)
        @messages_per_thread = Hash.new
        @total_message_count = 0
        @total_word_count = 0
    end

    def process(line)
        process_total_word_count(line[:message])
        process_commonly_used_words(line[:message])
    end

    def process_messages_by_thread(lines, thread_name)
        @messages_per_thread[thread_name] = lines.length
        @total_message_count += lines.length
    end

    def output(days_spent_on_discord)
        {
            commonly_used_words: @commonly_used_words.select{|word, count| count >= 10}.sort_by{|word, count| count}.reverse,
            per_thread: @messages_per_thread.sort_by{|thread_name, count| count}.reverse,
            average_words_per_message: (@total_word_count.to_f/@total_message_count).round(2),
            average_messages_per_day: (@total_message_count.to_f/days_spent_on_discord).round(2),
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
end