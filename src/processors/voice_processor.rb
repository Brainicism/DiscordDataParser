class VoiceProcessor
    def initialize
        @total_voice_channel_connections = 0
    end

    def process(_activity, event_type)
        prepare_total_voice_channel_connections(event_type)
    end

    def prepare_total_voice_channel_connections(event_type)
        return unless ['join_voice_channel'].include? event_type
        @total_voice_channel_connections += 1
    end

    def output
        {
            total_voice_channel_connections: @total_voice_channel_connections
        }
    end
end
