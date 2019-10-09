![demo](/examples/message_analysis_charts.png)
![demo](/examples/markov.png)

# Requirements
Ruby >=2.0

# Usage
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
--data-path=[PATH_TO_BACK_UP]   #specifies the directory of the backup
--word-min-length=[LENGTH]      #specifies a minimum length of commonly used word data
--thread-id=[ID]                #specifies a specific thread to perform message analysis on
--normalize-time=[true/false]   #parse message timestamps in the timezone they were sent from, default: true
--timezone=[TIMEZONE]           #specifies the timezone/offset to parse the data in. Will accept RFC 2822 specified timezones or ±HH:MM UTC offsets
--rebuild-binary                #rebuilds an executable using ocra
--quick-run                     #parse a subset of the available data for testing purposes
--update-events                 #see event section below
--verify-events                 #see event section below
````

**An executable version can also be found [here](https://github.com/Brainicism/DiscordDataParser/releases).** Simply execute it in the backup folder.

An HTML file is generated with various charts to display the processed data. 

Various charts are generated such as:  

- messages by date
- messages by day of week/time of day
- commonly used messages/words
- most active threads
- time spent by OS/location/device
- most used reactions
- game play count

Various markov strings are generated and displayed.

Other miscellaneous data is also displayed such as:

- total message count
- average words per message
- average messages per day
- total sessions, average session length
- total reactions added/removed
- total voice channel joins

Human-readable versions of each message thread are also generated in `output/prettified`.

# Requesting your data
You can retrieve your past Discord messages by following the instructions in the article below.
https://support.discordapp.com/hc/en-us/articles/360004027692

### Activity Data
Many of the generated charts/analyses rely on activity data provided in the data backup, which not every user may have. My hypothesis is that this data is only generated if the user has toggled the `Use data to improve Discord` setting under `Privacy & Safety` in the client settings. If this data is not present, the corresponding charts/information will not appear. 

# Event Types
Given that there is no documented list of possible `event_types`s, the repo contains a `event_list.txt` file that contains every `event_type` seen so far. Running the app with the `--verify-events` flag will check the data backup against `event_list.txt` and display any events missing. If there events are of interest, we should parse them, and re-run the app with `--update-events` to add the new events to `event_list.txt`.
