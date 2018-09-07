
![demo](/examples/messages_by_date.png)
![demo](/examples/os_device_words_location.png)


# Usage  
## Executable:
The executable can be found [here](https://github.com/Brainicism/DiscordDataParser/releases), simply execute it in the backup folder.  
A guide to using it can be found [here](how_to_run_exe.md).  

## Running the source:  
#### Requirements:  
Ruby >= 2.0.0
```
ruby -v
```

Bundle is required to manage dependencies
```
gem install bundle
bundle
```

To run the application:
```
ruby app.rb --data-path=[PATH_TO_BACK_UP]
```
#### Arguments
```
--datapath=[PATH]               #specifies the directory of the backup, defaults to current working directory ./
--word-min-length=[LENGTH]      #specifies a minimum length of commonly used word data
--thread-id=[ID]                #specifies a specific thread to perform message analysis on
--normalize-time=[true/false]   #parse message timestamps in the timezone they were sent from, default: true
--timezone=[TIMEZONE]           #specifies the timezone/offset to parse the data in. Will accept RFC 2822 specified timezones or ±HH:MM UTC offsets
--rebuild-binary                #rebuilds an executable using ocra
--quick-run                     #parse a subset of the available data for testing purposes
--update-events                 #see event section below
--verify-events                 #see event section below
````

An HTML file is generated with various charts to display the processed data. 

The following .csv files are also generated with the processed data:
- Messages by day
- Messages by day of week
- Messages by time of day
- Messages by thread
- Most frequently used phrases
- Most frequently used words
- Game play count
- Reactions by use
- Time spent per device
- Time spent per location
- Time spent per OS

The following information is shown:
- Total number of messages sent
- Average message length
- Average messages per day
- Total number of sessions
- Total times app opened
- Average length per session
- Total number of reactions added/removed
- Total number of voice channel joins

Human readable versions of each message thread are also generated.

# Requesting your data
You can retrieve your past Discord messages by following the instructions in the article below.
https://support.discordapp.com/hc/en-us/articles/360004027692

### Activity Data
Many of the generated charts/analyses rely on activity data provided in the data backup, which not every user may have. My hypothesis is that this data is only generated if the user has toggled the `Use data to improve Discord` setting under `Privacy & Settings` in the client settings. If this data is not present, the corresponding charts/information will not appear. 

# Event Types
Given that there is no documented list of possible `event_types`s, the repo contains a `event_list.txt` file that contains every `event_type` seen so far. Running the app with the `--verify-events` flag will check the data backup against `event_list.txt` and display any events missing. If there events are of interest, we should parse them, and re-run the app with `--update-events` to add the new events to `event_list.txt`.
