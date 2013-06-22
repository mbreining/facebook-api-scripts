#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'net/https'
require 'json'

DELIMITER = ","
SHORTENERS = ["http://bit.ly", "http://j.mp", "http://on.fb.me"]

open("output.txt", "w") do |output_file|
  open("input.txt", "r") do |in_file|
    in_file.each_line do |line|
      tokens = line.split(DELIMITER)
      campaign_id = tokens[0].strip
      adgroup_id = tokens[1].strip
      url = tokens[2].strip
      puts "Processing #{url}"

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
      response = http.request(request)
      data = JSON.parse(response.body)

      type = data["type"]
      if type == "photo"
        puts "\tFound photo page post; processing..."
        message = data["message"]
        if message
          links = URI.extract(message).map{ |link| link.start_with?("http:") ? link : nil }.compact
        end
      elsif type == "link"
        puts "\tFound link page post; processing..."
        links = [data["link"]]
      else
        puts "\tInvalid page post type: #{type}; skipping..."
        next
      end

      if links and not links.empty?
        puts "\tFound links: #{links}; processing..."
        links.each do |link|
          puts "\tFound link: #{link}; processing..."
          if SHORTENERS.inject(false) { |result, shortener| link.include?(shortener) ? true : result }
            puts "\tFound shortened link: #{link}; expanding..."
            response = Net::HTTP.get_response(URI.parse("http://urlex.org/json/#{link}"))
            data = response.body
            link = JSON.parse(data)[link]
            if link
              puts "\tExpanded link: #{link}"
            else
              puts "\tLink cannot be expanded; skipping..."
              next
            end
          end

          if link.include? "ev_cl="
            ev_cl = link.split("ev_cl=")[1].split("&")[0]
            puts "\tFound ev_cl: #{ev_cl}"
            output_file.puts campaign_id + DELIMITER + adgroup_id + DELIMITER + ev_cl
          else
            puts "\tev_cl not found: #{link}; skipping..."
            next
          end
        end
      else
        puts "\tNo links found in page post; skipping..."
        next
      end
    end
  end
end
