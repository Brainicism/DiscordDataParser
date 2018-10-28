class AccountAnalyzer
    def initialize(path, params)
        @path = path
        @params = params
        @avatar_path = Dir.glob("#{@path}/avatar.*")[0]
        # Use globbing pattern to allow detection of multiple
        # avatar file formats
    end

    def call
        account_details = JSON.parse File.read "#{@path}/user.json"
        {
            output_files: [],
            misc_data: {
                avatar_path: "#{@avatar_path}"
            },
            output_data: {
                username: account_details['username'],
                user_tag: account_details['discriminator'],
                email: account_details['email']
            }
        }
    end
end

