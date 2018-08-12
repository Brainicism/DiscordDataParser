class ResultRenderer
    attr_reader :output
    def initialize(output)
        @output = output
        @template = ERB.new File.read("public/index.erb"), nil, "%"
    end

    def render
        @anime = @output.to_json
        File.open('output/index.html', 'w') { |file| file.write(@template.result(binding)) }
    end
end
