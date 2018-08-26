class MessagePrettifierProcessor
    def process_messages_by_thread(lines, thread_name, thread_id)
        prettified_messages = lines.map do |line|
            "[#{line[:date_time].strftime('%m/%d/%Y %H:%M')}] #{line[:message]}"
        end.reverse.join("\n")
        Utils.write_output_txt(prettified_messages, 'prettified/messages', "#{thread_name}_#{thread_id}.txt")
    end
end
