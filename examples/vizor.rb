#!/usr/bin/env ruby
require 'dcell'

DCell.start :id => "vizor"

class Vizor
  include Celluloid


  def initialize
    puts "Lets do this!"
    @n = 0

    seed_crawl
  end

  def get_next_link
    @n += 1

    @links.pop
  end

  def seed_crawl
    @links = ['https://dir.yahoo.com/']
  end

end

Vizor.supervise_as :vizor
sleep
