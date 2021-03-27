# encoding: UTF-8

class MessageByContentProcessor
    def initialize(params)
        @commonly_used_messages = Hash.new(0)
        @commonly_used_words = Hash.new(0)
        @messages_per_thread = {}
        @total_message_count = 0
        @total_word_count = 0
        @sentences = []
        @params = params
    end

    def process(line)
        return if line[:message].nil?
        line[:message] = line[:message].force_encoding('UTF-8')
        prepare_total_word_count(line[:message])
        prepare_commonly_used_messages(line[:message])
        prepare_commonly_used_words(line[:message])
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
    def prepare_commonly_used_messages(message)
        @commonly_used_messages[message.strip.downcase] += 1
    end

    def prepare_commonly_used_words(message)
        message.strip.downcase.split(' ').each do |word|
            min_word_length = @params[:word_min_length] ? @params[:word_min_length].to_i : 5
            if word.length > min_word_length && !Utils.word_is_mention_or_emoji(word)
                @commonly_used_words[word] += 1
            end
        end
    end

    def prepare_total_word_count(message)
        @total_word_count += message.split(' ').length
    end
end
