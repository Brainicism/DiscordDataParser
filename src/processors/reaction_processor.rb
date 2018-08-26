class ReactionProcessor
    UNKNOWN_REACTION_PATTERN = /\A[?]+\z/

    def initialize
        @total_reactions_added = 0
        @total_reactions_removed = 0
        @reactions_count_hash = Hash.new(0)
    end

    def process(activity, event_type)
        return unless ['add_reaction', 'remove_reaction'].include? event_type
        if event_type == 'add_reaction'
            @total_reactions_added += 1
            @reactions_count_hash[activity['emoji_name']] += 1
        elsif event_type == 'remove_reaction'
            @total_reactions_removed += 1
        end
    end

    def output
        {
            total_reactions_added: @total_reactions_added,
            total_reactions_removed: @total_reactions_removed,
            reactions_by_use: @reactions_count_hash.reject { |key| key =~ UNKNOWN_REACTION_PATTERN }.sort_by { |_reaction, count| count }.reverse
        }
    end
end
