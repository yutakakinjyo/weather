require 'tweetstream'
require 'twitter'
require 'json'
require 'rest-client'

consumer_key = ENV['TWITTER_CONSUMER_KEY']
consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
access_token = ENV['TWITTER_ACCESS_TOKEN']
access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']

weather_hacks = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=471010'

TweetStream.configure do |config|
  config.consumer_key = consumer_key
  config.consumer_secret = consumer_secret
  config.oauth_token = access_token
  config.oauth_token_secret = access_token_secret
  config.auth_method = :oauth
end

rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key = consumer_key
  config.consumer_secret = consumer_secret
  config.access_token = access_token
  config.access_token_secret = access_token_secret
end

res_json =  RestClient.get weather_hacks
format_json = JSON.parse(res_json)
title = format_json['title']
telop = format_json['forecasts'][0]['telop']
data_label = format_json['forecasts'][0]['dataLabel']

stream_client = TweetStream::Client.new
stream_client.track("@SubYutaka") do |status|
  puts "#{status.user.screen_name}"
  tweet = "@#{status.user.screen_name} #{Time.now} #{title} #{telop}"
  rest_client.update(tweet)
  puts "#{status.user.name} #{status.text}"
end
