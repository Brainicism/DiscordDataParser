class ResultRenderer
    attr_reader :output

    def initialize(output)
        @output = output
        @html_template = ERB.new File.read("#{File.expand_path("../public/index.html.erb", __dir__)}"), nil, '%'
        @js_template = ERB.new File.read("#{File.expand_path("../public/index.js.erb", __dir__)}"), nil, '%'

    end

    def render
        @json_output = @output.to_json
        @username = @output[:username]
        @specified_thread_name = @output[:specified_thread_name]
        @utc_offset = @output[:utc_offset]
        File.open('output/visualizations/index.js', 'w') { |file| file.write(@js_template.result(binding)) }
        File.open('output/visualizations/index.html', 'w') { |file| file.write(@html_template.result(binding)) }
    end
end
