class VoiceProcessor 
    def initialize
        @total_voice_channel_connections = 0
    end

    def process(activity)
        @total_voice_channel_connections += 1
    end

    def output
        {
            total_voice_channel_connections: @total_voice_channel_connections
        }
    end
end