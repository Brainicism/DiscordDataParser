# encoding: UTF-8
require 'marky_markov'

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
        prepare_markov(line[:message])
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
            total_message_count: @total_message_count,
            markov_sentences: process_markov
        }
    end

    private

    def prepare_markov(message)
        @sentences.push message if message.split(' ').length > 5
    end

    def process_markov
        markov = MarkyMarkov::TemporaryDictionary.new
        FileUtils.mkdir_p 'tmp'
        File.open('tmp/sentences.txt', 'w') { |file| file.write(@sentences.join("\n")) }
        markov.parse_file 'tmp/sentences.txt'
        markov_sentences = Array.new(100) { |_i| markov.generate_1_sentences }
        Utils.write_output_txt(markov_sentences.join("\n"), '', 'markov')
        markov_sentences
    end

    def prepare_commonly_used_messages(message)
        @commonly_used_messages[message.strip.downcase] += 1
    end

    def prepare_commonly_used_words(message)
        message.strip.downcase.split(' ').each do |word|
            if word.length > (@params[:word_min_length].to_i || 5) && !Utils.word_is_mention_or_emoji(word)
                @commonly_used_words[word] += 1
            end
        end
    end

    def prepare_total_word_count(message)
        @total_word_count += message.split(' ').length
    end
end
