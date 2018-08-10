class VerifyEventsProcessor
    def initialize(verify, update)
        @event_list = []
        @update = update
        @verify = verify
    end

    def process(event_type)
        return unless @update || @verify
        @event_list << event_type if !@event_list.include? event_type
    end

    def output
        return {} unless @update || @verify

        old_event_list = File.read('event_list.txt').split("\n")
        new_events = @event_list - old_event_list
        return {} if new_events.length == 0
        raise "New event_types found.\nCheck if the new events have any interesting details, then re-run with --update-events to update the current event list.\n #{new_events}" if @verify
        if @update
            File.open('event_list.txt', 'w') do |file| 
                file.write(@event_list.sort.join("\n"))
            end
            raise "New event_types saved to current event list. \n #{new_events}"
        end
        {}
    end
end
