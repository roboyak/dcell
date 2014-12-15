require 'slurp'
require 'redis'
require 'daemons'
require 'logger'

#url = "https://dir.yahoo.com/arts"

r = Redis.new(:url => "redis://rediscloud:ravePEve3UT2ugad@pub-redis-11154.us-east-1-4.4.ec2.garantiadata.com:11154")

r.del 'yahoo-urls'
r.sadd('yahoo-urls', "https://dir.yahoo.com/arts") 
r.lpush('crawl_queue', "https://dir.yahoo.com/arts") 

class Crawl

	def initialize(params = {})
	    @logger       = Logger.new("./slurp/slurp_#{Time.now.strftime('%Y%m%d%H%M%S')}.log", 'daily')
	    @logger.level = Logger::DEBUG    		

		@r = params[:redis] 

		url = get_url
		puts url.inspect

		unless url.nil?
			puts "Crawling #{url}"
			page = Slurp::Page.new(url, { :logger => @logger })

			page.crawl

			page.to_html

			save_unique_links(page)

			page.save_categories

			page.save_sites
			
			page.to_json
		else
			@logger.info "nothing to do"
		end
	end

	def get_url
		URI(@r.rpop('crawl_queue'))
	end

	def save_unique_links(page)
	  	page.queue_links.each{ |l| 
	  		if @r.sadd('yahoo-urls', l.to_s) 
	  			@r.lpush('crawl_queue', l.to_s) 
	  		end
	  	}
	end
end

options = { :backtrace => true, :dir => '../log/', :log_output => true }

loop do
	crawler = Crawl.new({ :redis => r })

	sleep (1)
end

puts "yahoo urls"
puts r.smembers('yahoo-urls')
puts ""

puts "crawl queue"
puts r.lrange('crawl_queue', 0 , -1)