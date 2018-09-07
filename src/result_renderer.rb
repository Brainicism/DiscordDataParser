class ResultRenderer
    attr_reader :output

    def initialize(final_output, activity_available)
        @output = final_output[:output_data]
        @html_template = ERB.new File.read("#{File.expand_path("../public/index.html.erb", __dir__)}"), nil, '%'
        @js_template = ERB.new File.read("#{File.expand_path("../public/index.js.erb", __dir__)}"), nil, '%'
        @activity_available = activity_available
        @misc_data = final_output[:misc_data]
    end

    def render
        @json_output = @output.to_json
        @username = @output[:username]
        @usertag = @output[:usertag]
        @specified_thread_name = @output[:specified_thread_name]
        @utc_offset = @output[:utc_offset]

        File.open('output/visualizations/index.js', 'w') { |file| file.write(@js_template.result(binding)) }
        File.open('output/visualizations/index.html', 'w') { |file| file.write(@html_template.result(binding)) }
    end
end
