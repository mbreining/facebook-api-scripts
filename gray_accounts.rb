#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'net/https'
require 'json'

DELIMITER = "|"
FACEBOOK_API_ME = "https://graph.facebook.com/me"

open("output.txt", "w") do |output_file|
  open("input.txt", "r") do |in_file|
    in_file.each_line do |line|
      tokens = line.split(DELIMITER)
      user_id = tokens[0].strip
      account_name = tokens[1].strip
      access_token = tokens[2].strip
      puts "Processing #{account_name}"

      url = "#{FACEBOOK_API_ME}/?access_token=#{access_token}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
      response = http.request(request)
      data = JSON.parse(response.body)

      next if data["name"]

      puts "\tFound gray account #{account_name}"
      output_file.puts "#{user_id}#{DELIMITER}#{account_name}"
    end
  end
end
