#!/usr/bin/env ruby

require "rubygems"
require "twitter"
require "json"
require "yaml"
require "./config"

cfg = TwitterConfig.new(ENV['CONFIG_FILE'] || './config.yml')
cfg.check!

TWITTER_USER = cfg.username
MAX_AGE_IN_DAYS = cfg.max_age

CONSUMER_KEY = cfg.consumer_key
CONSUMER_SECRET = cfg.consumer_secret
OAUTH_TOKEN = cfg.token
OAUTH_TOKEN_SECRET = cfg.secret

IDS_TO_SAVE_FOREVER = cfg.tweets_to_keep


MAX_AGE_IN_SECONDS = MAX_AGE_IN_DAYS*24*60*60
NOW_IN_SECONDS = Time.now

TWEETS_PER_REQUEST = 200

### A METHOD ###
#

def delete_from_twitter(tweet, client)
  begin
    client.destroy_status(tweet.id)
  rescue StandardError => e
    puts e.inspect
    puts "Error deleting #{tweet.id}; exiting"
    exit
  else
    puts "Deleted #{tweet.id}"
  end
end

### WE BEGIN ###

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONSUMER_KEY
  config.consumer_secret     = CONSUMER_SECRET
  config.access_token        = OAUTH_TOKEN
  config.access_token_secret = OAUTH_TOKEN_SECRET
end

puts ""
puts "What's that sound...?"
puts ""

tweets = []
got_tweets = true
oldest_tweet_id = 9000000000000000000

while got_tweets do
  begin
    new_tweets = client.user_timeline(TWITTER_USER, {:count => TWEETS_PER_REQUEST,
                                                     :max_id => oldest_tweet_id,
                                                     :include_entities => false,
                                                     :include_rts => true})

    if (new_tweets.length > 0) then
      puts "Got #{new_tweets.length} more tweets, latest is #{new_tweets.last.id}"
      oldest_tweet_id = new_tweets.last.id - 1
      tweets += new_tweets
    else
      got_tweets = false
    end

  rescue Twitter::Error::TooManyRequests => e
    puts "Hit the rate limit; pausing for #{e.rate_limit.reset_in} seconds"
    sleep e.rate_limit.reset_in
    retry

  rescue StandardError => e
    puts e.inspect
    exit
  end
end

puts ""
puts "Got #{tweets.length} tweets total"
puts ""

tweets.each do |tweet|
  begin
    tweet_age = NOW_IN_SECONDS - tweet.created_at
    tweet_age_in_days = (tweet_age/(24*60*60)).round
    if (tweet_age < MAX_AGE_IN_SECONDS) then
      puts "Ignored a tweet #{tweet_age_in_days} days old"
    elsif IDS_TO_SAVE_FOREVER.include?(tweet.id) then
      puts "Ignored a tweet that is to be saved forever"
    else
      puts "Deleting a tweet #{tweet_age_in_days} days old"
      delete_from_twitter(tweet, client)
    end

    puts "  #{tweet.text}"
    puts ""

  rescue Twitter::Error::TooManyRequests => e
    puts "Hit the rate limit; pausing for #{e.rate_limit.reset_in} seconds"
    sleep e.rate_limit.reset_in
    retry

  rescue StandardError => e
    puts e.inspect
    exit
  end
end
