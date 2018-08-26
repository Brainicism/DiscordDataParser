class MessageByContentProcessor
    def initialize(params)
        @commonly_used_messages = Hash.new(0)
        @commonly_used_words = Hash.new(0)
        @messages_per_thread = {}
        @total_message_count = 0
        @total_word_count = 0
        @params = params
    end

    def process(line)
        line[:message] = line[:message].force_encoding('UTF-8') if line[:message]
        process_total_word_count(line[:message])
        process_commonly_used_messages(line[:message])
        process_commonly_used_words(line[:message])
    end

    def process_messages_by_thread(lines, thread_name, _thread_id)
        @messages_per_thread[thread_name] = lines.length
        @total_message_count += lines.length
    end

    def output(days_spent_on_discord)
        {
            commonly_used_messages: @commonly_used_messages.select { |_message, count| count >= 10 }.sort_by { |_message, count| count }.reverse,
            commonly_used_words: @commonly_used_words.select { |_word, count| count >= 10 }.sort_by { |_word, count| count }.reverse,
            per_thread: @messages_per_thread.sort_by { |_thread_name, count| count }.reverse,
            average_words_per_message: (@total_word_count.to_f / @total_message_count).round(2),
            average_messages_per_day: (@total_message_count.to_f / days_spent_on_discord).round(2),
            total_message_count: @total_message_count
        }
    end

    private

    def process_commonly_used_messages(message)
        return if message.nil?
        @commonly_used_messages[message.strip.downcase] += 1
    end

    def process_commonly_used_words(message)
        return if message.nil?
        message.strip.downcase.split(' ').each do |word|
            if word.length > (@params[:word_min_length].to_i || 5) && !Utils.word_is_mention_or_emoji(word)
                @commonly_used_words[word] += 1
            end
        end
    end

    def process_total_word_count(message)
        return if message.nil?
        @total_word_count += message.split(' ').length
    end
end
