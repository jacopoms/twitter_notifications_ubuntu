#!/usr/bin/env ruby

require 'tweetstream'
require 'open-uri'
require 'fileutils'

@dir = File.expand_path(File.join(File.dirname(__FILE__)))
@icon = "#{@dir}/icon"
@icon_default = "#{@dir}/icon_light.png"
@icon_error= "#{@dir}/icon_light_error.png"
@icon_dm = "#{@dir}/icon_light_dm.png"

myName = "jackopo"

TweetStream.configure do |config|
  config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
  config.oauth_token = ENV["TWITTER_OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["TWITTER_OAUTH_TOKEN_SECRET"]
  config.auth_method = :oauth
end


def get_image (img_url)
  begin
    File.open(@icon, 'wb') do |file|
      file << open(img_url).read
    end
  rescue
    File.open(@icon, 'wb') do |file|
      file << open(@icon_default).read
    end
  end
end

daemon = TweetStream::Daemon.new("tweetstream-daemon")

daemon.on_error do |message|
  title = "Error: "
  body =  message
  system("notify-send --expire-time=10000 --icon=#{@icon_error}  \"#{title}\" \"#{body}\"")
end

daemon.on_direct_message do |direct_message|
  unless direct_message.sender.screen_name == myName
    title = direct_message.sender? ? "DM from @" + direct_message.sender.screen_name : "DM: @ ????"
    body = direct_message.text? ? direct_message.text : direct_message
    get_image(direct_message.sender.profile_image_url)
    system("notify-send --expire-time=10000 --icon=#{@icon}  \"#{title}\" \"#{body}\"")
    system("aplay #{@dir}/chime_up.wav")
  end
end

daemon.on_timeline_status do |status|
  title = status.user? ? "@" + status.user.screen_name : "Tweet: "
  body = status.text? ? status.text : status
  get_image(status.user.profile_image_url)
  system("notify-send --expire-time=10000 --icon=#{@icon}  \"#{title}\" \"#{body}\"")
end

daemon.userstream