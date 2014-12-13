#!/usr/bin/env ruby
require 'dcell'

DCell.start
vizor_node = DCell::Node["vizor"]

puts "Waking crawler, hidden dragon.."

require 'slurp'

opts = {}
http = Slurp::HTTP.new(opts)

loop do
  link = vizor_node[:vizor].get_next_link

  unless link.nil?
	  page = http.fetch_page(link)

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