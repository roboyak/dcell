require 'daemons'

Daemons.run_proc('crawl.rb') do
  loop do
    sleep(1)
  end
end