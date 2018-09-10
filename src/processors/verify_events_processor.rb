class VerifyEventsProcessor
    def initialize(verify, update)
        @event_list = []
        @update = update
        @verify = verify
    end

    def process(_activity, event_type)
        prepare_event_list(event_type)
    end

    def prepare_event_list(event_type)
        return unless @update || @verify
        @event_list << event_type unless @event_list.include? event_type
    end

    def output
        return {} unless @update || @verify
        old_event_list = File.read('event_list.txt').split("\n")
        new_events = @event_list - old_event_list
        if new_events.length.zero?
            puts 'event_types list is up to date'
            exit
        end

        if @update
            new_event_list = old_event_list + new_events
            File.open('event_list.txt', 'w') do |file|
                file.write(new_event_list.sort.join("\n"))
            end
            puts "New event_types saved to current event list. \n #{new_events}"
            exit
        end

        if @verify
            puts "New event_types found.\nCheck if the new events have any interesting details, then re-run with --update-events to update the current event list.\n#{new_events}"
            exit
        end
    end
end
