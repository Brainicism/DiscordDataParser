class ArgParser
    module ArgType
        STRING = 0
        INTEGER = 1
        BOOL = 2
    end
    ALLOWED_FLAGS = [
        { flag: '--update-events', param_key: :update_events },
        { flag: '--verify-events', param_key: :verify_events },
        { flag: '--quick-run', param_key: :quick_run },
        { flag: '--rebuild-binary', param_key: :rebuild_binary }
    ].freeze
    ALLOWED_FLAGS_WITH_ARG = [
        { flag: '--data-path=', param_key: :data_path, type: ArgType::STRING },
        { flag: '--word-min-length=', param_key: :word_min_length, type: ArgType::INTEGER },
        { flag: '--months=', param_key: :months_look_back, type: ArgType::INTEGER },
        { flag: '--thread-id=', param_key: :thread_id, type: ArgType::STRING },
        { flag: '--timezone=', param_key: :timezone, type: ArgType::STRING },
        { flag: '--normalize-time=', param_key: :normalize_time, type: ArgType::BOOL}
    ].freeze

    class << self
        def parse(args)
            parsed_params = {}
            ALLOWED_FLAGS.each do |param|
                if args.include? param[:flag]
                    parsed_params[param[:param_key]] = true
                    args.delete(param[:flag])
                end
            end

            ALLOWED_FLAGS_WITH_ARG.each do |param|
                flag_with_arg = args.find { |arg| arg.start_with? param[:flag] }
                if flag_with_arg
                    parsed_params[param[:param_key]] = extract_argument(flag_with_arg.dup, param[:flag], param[:type])
                    args.delete(flag_with_arg)
                end
            end

            raise "Unknown flags: #{args.join(', ')}" unless args.empty?
            parsed_params
        end

        def extract_argument(flag_with_arg, flag, type)
            flag_with_arg.slice! flag
            case type
            when ArgType::STRING
                flag_with_arg
            when ArgType::INTEGER
                flag_with_arg.to_i
            when ArgType::BOOL
                return true if flag_with_arg.casecmp('true').zero?
                return false if flag_with_arg.casecmp('false').zero?
                raise "#{flag_with_arg} is invalid boolean value"
            else
                raise "#{type} doesn't exist"
            end

        end
    end
end
