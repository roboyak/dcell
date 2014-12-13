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