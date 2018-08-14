class AccountAnalyzer
    def initialize(path, params)
        @path = path
        @params = params
    end

    def call
        account_details = JSON.parse File.read "#{@path}/user.json"
        {
            output_files: [],
            output_strings: [],
            output_raw: {
                username: account_details['username'],
                email: account_details['email']
            }
        }
    end
end