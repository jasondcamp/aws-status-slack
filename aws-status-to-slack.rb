#!/usr/bin/env ruby

require 'slack-ruby-client'
require 'logger'
require 'crack'
require 'json'
require 'time'

STATUS_TXT = "status.txt"
logger = Logger.new(STDOUT)
incidents = []

if ENV['SLACK_ROOM'].nil?
  puts "Environment variable SLACK_ROOM is not set!"
  exit 1
end

if ENV['SLACK_TOKEN'].nil?
  puts "Environment variable SLACK_TOKEN is not set!"
  exit 1
end

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end
client = Slack::Web::Client.new

# Read in the local status
logger.info("Reading existing statuses")
if File.exists?(STATUS_TXT)
  incidents = File.read(STATUS_TXT).chomp.split("|")
end

# Read in the xml page and convert to json and then hash
logger.info("Getting XML and parsing")
response = Net::HTTP.get(URI.parse('https://status.aws.amazon.com/rss/all.rss'))
response_json  = JSON.parse(Crack::XML.parse(response).to_json)

response_json['rss']['channel']['item'].reverse_each do |item|
  guid = item['guid'].split("#")[1]

  if incidents.include?(guid)
    logger.info("Skipping incident #{guid}, already sent")
  else
    logger.info("Sending new incident #{guid} to slack...")
    slack_txt = "<http://status.aws.amazon.com/##{guid}|*#{item['title']}*>"

    if item['title'].include?("[RESOLVED]")
      slack_txt += " :white_check_mark:"
    elsif item['title'].include?("degradation")
      slack_txt += " :warning:"
    end

    slack_txt += "\n_#{item['pubDate']}_\n#{item['description']}"
    client.chat_postMessage(channel: ENV['SLACK_ROOM'], text: slack_txt, as_user: true)
    incidents.push(guid)
  end
end

# Save incidents back to status page and exit
logger.info("Saving incidents to status file")
File.write(STATUS_TXT, incidents.join("|"), mode: "w")
logger.info("Finished parsing RSS, exiting")

