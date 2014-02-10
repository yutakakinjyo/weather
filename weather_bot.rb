require 'tweetstream'
require 'twitter'
require 'json'
require 'rest-client'
require 'rexml/document'

def create_area_code_hash(xml)
  h = Hash::new
  doc = REXML::Document.new(xml)
  doc.elements.each('rss/channel/ldWeather:source/pref/city') do |element|
    h[element.attributes['title']] = element.attributes['id']
  end
  return h
end

def is_exit_location(h,str)
  h.each do |key,value|
    if str.include?(key) then
      return key
    end
  end
  return nil
end

consumer_key = ENV['TWITTER_CONSUMER_KEY']
consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
access_token = ENV['TWITTER_ACCESS_TOKEN']
access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']

WEATHER_HACKS = 'http://weather.livedoor.com/forecast/webservice/json/v1?city='
AREA_CODE = 'http://weather.livedoor.com/forecast/rss/primary_area.xml'

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

stream_client = TweetStream::Client.new
stream_client.track("@SubYutaka") do |status|
  puts "#{status.user.screen_name}"
  puts "#{status.user.name} #{status.text}"
  res_xml =  RestClient.get AREA_CODE
  h = create_area_code_hash(res_xml)
  key = is_exit_location(h,status.text)
  if !key.nil? then
    res_json =  RestClient.get(WEATHER_HACKS + h[key])
    format_json = JSON.parse(res_json)
    title = format_json['title']
    telop = format_json['forecasts'][0]['telop']
    data_label = format_json['forecasts'][0]['dataLabel']

    tweet_str = "@#{status.user.screen_name} #{title} #{telop} #{Time.now}"
  else 
    tweet_str = "@#{status.user.screen_name} データがありません( ˘ω˘)　#{Time.now}"
  end
  rest_client.update(tweet_str)
end
