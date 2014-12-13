#!/usr/bin/env ruby
require 'dcell'

DCell.start
vizor_node = DCell::Node["vizor"]

puts "Waking crawler, hidden dragon.."

loop do
  link = vizor_node[:vizor].get_next_link

  unless link.empty?
	  page = Page.new(link)

	  page.crawl

	  page.to_html

	  page.queue_links	

	  page.save_categories

	  page.to_json
	else
		puts "Nothing to do ("
	end

   sleep 1
end

module Slurp
  class Page

    attr_reader :url

    def initialize(url, params = {})
   	  puts "Initializing page with url: #{url}"
      @url = url
    end

    def crawl
   	  puts "Crawling url: #{url}"
    end

    def queue_links
      puts "Q'ing links"
    end

    def save_categories
      puts "Saving categories"
    end

    def to_html
      puts "to_html"
    end

    def to_json
      puts "to_json"
    end
  end
end

