#!/usr/bin/env ruby
require "rubygems"
require "twitter"
require "json"
require "faraday"
require "./config"

cfg = TwitterConfig.new(ENV['CONFIG_FILE'] || './config.yml')
cfg.check!

TWITTER_USER = cfg.username
MAX_AGE_IN_DAYS = cfg.max_age

CONSUMER_KEY = cfg.consumer_key
CONSUMER_SECRET = cfg.consumer_secret
OAUTH_TOKEN = cfg.token
OAUTH_TOKEN_SECRET = cfg.secret

MAX_AGE_IN_SECONDS = MAX_AGE_IN_DAYS*24*60*60
NOW_IN_SECONDS = Time.now

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONSUMER_KEY
  config.consumer_secret     = CONSUMER_SECRET
  config.access_token        = OAUTH_TOKEN
  config.access_token_secret = OAUTH_TOKEN_SECRET
end

faves = []
oldest_fave_id = 9000000000000000000
got_faves = true

puts ""
puts "First we collect your faves ✨"

while got_faves do
  begin
    new_faves = client.favorites(TWITTER_USER,{:count => 200, :max_id => oldest_fave_id})

    if (new_faves.length > 0) then
      oldest_fave_id = new_faves.last.id - 1 # the - 1 is important, because of course it is
      faves += new_faves
      puts "Got more faves, including tweet #{new_faves.last.id}..."
    else
      puts "No more faves to get!"
      got_faves = false
    end

  rescue Twitter::Error::TooManyRequests => e
    puts "Hit the rate limit. Pausing for #{e.rate_limit.reset_in} seconds..."
    sleep e.rate_limit.reset_in
    retry

  rescue StandardError => e
    puts e.inspect
    exit
  end
end

puts ""
puts "The great unfaving begins 🙅"

faves.each do |fave|
  puts "Unfavoriting tweet #{fave.id}..."
  begin
    tweet_age = NOW_IN_SECONDS - fave.created_at
    tweet_age_in_days = (tweet_age/(24*60*60)).round
    if (tweet_age < MAX_AGE_IN_SECONDS) then
      puts "Ignored a faved tweet #{tweet_age_in_days} days old"
    else
      puts "Deleting a fave #{tweet_age_in_days} days old"
      client.unfavorite(fave.id)
    end

  rescue Twitter::Error::TooManyRequests => e
    puts "Hit the rate limit. Pausing for #{e.rate_limit.reset_in} seconds..."
    sleep e.rate_limit.reset_in
    retry

  rescue StandardError => e
    puts e.inspect
    exit
  end
end

puts ""
puts "Done! 🙌"
puts ""
