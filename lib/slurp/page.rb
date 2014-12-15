require 'nokogiri'
require 'ostruct'
require 'webrick/cookie'
require 'stringex'

module Slurp
  class Page

    # The URL of the page
    attr_reader :url
    # The raw HTTP response body of the page
    attr_reader :body
    # Headers of the HTTP response
    attr_reader :headers
    # URL of the page this one redirected to, if any
    attr_reader :redirect_to
    # Exception object, if one was raised during HTTP#fetch_page
    attr_reader :error

    # OpenStruct for user-stored data
    attr_accessor :data
    # Integer response code of the page
    attr_accessor :code
    # Boolean indicating whether or not this page has been visited in PageStore#shortest_paths!
    attr_accessor :visited
    # Depth of this page from the root of the crawl. This is not necessarily the
    # shortest path; use PageStore#shortest_paths! to find that value.
    attr_accessor :depth
    # URL of the page that brought us to this page
    attr_accessor :referer
    # Response time of the request for this page in milliseconds
    attr_accessor :response_time

    #
    # Create a new page
    #
    def initialize(url, params = {})
      @url = url
      @data = OpenStruct.new

      @parts            = url.path.downcase.split("/")      
      category          = @parts.pop.to_s

      @dir              = Hash.new
      @dir["url"]       = url
      @dir["path"]      = url.path
      @dir["location"]  = "./slurp/yahoo#{url.path}"
      @dir["raw_html"]  = "#{@dir["location"]}#{@dir["page"]}.html"
      @dir["json_doc"]  = "#{@dir["location"]}#{@dir["page"]}.json"
      @dir["timestamp"] = Time.now

      @logger = params[:logger]
      @code = params[:code]
      @headers = params[:headers] || {}
      @headers['content-type'] ||= ['']
      @aliases = Array(params[:aka]).compact
      @referer = params[:referer]
      @depth = params[:depth] || 0
      @redirect_to = to_absolute(params[:redirect_to])
      @response_time = params[:response_time]
      @body = params[:body]
      @error = params[:error]

      @fetched = !params[:code].nil?
    end

    #
    # Array of distinct A tag HREFs from the page
    #
    def links(mode='yahoo')
      return @links unless @links.nil?
      @links = []
      return @links if !doc
      doc.search("//a[@href]").each do |a|
        if mode == 'yahoo'
          u = a['href'].downcase
        else
          u = a['href']
        end
        next if u.nil? or u.empty?
        #abs = to_absolute(u) rescue next
        abs = to_abs(u) rescue next
        @links << abs if in_domain?(abs)
      end
      @links.uniq!
      @links
    end

    #
    # Nokogiri document for the HTML body
    #
    def doc
      return @doc if @doc
      @doc = Nokogiri::HTML(@body) if @body && html? rescue nil
    end

    #
    # Delete the Nokogiri document and response body to conserve memory
    #
    def discard_doc!
      links # force parsing of page links before we trash the document
      @doc = @body = nil
    end

    #
    # Was the page successfully fetched?
    # +true+ if the page was fetched with no error, +false+ otherwise.
    #
    def fetched?
      @fetched
    end

    #
    # Array of cookies received with this page as WEBrick::Cookie objects.
    #
    def cookies
      WEBrick::Cookie.parse_set_cookies(@headers['Set-Cookie']) rescue []
    end

    #
    # The content-type returned by the HTTP request for this page
    #
    def content_type
      headers['content-type'].first
    end

    #
    # Returns +true+ if the page is a HTML document, returns +false+
    # otherwise.
    #
    def html?
      !!(content_type =~ %r{^(text/html|application/xhtml+xml)\b})
      true
    end

    #
    # Returns +true+ if the page is a HTTP redirect, returns +false+
    # otherwise.
    #
    def redirect?
      (300..307).include?(@code)
    end

    #
    # Returns +true+ if the page was not found (returned 404 code),
    # returns +false+ otherwise.
    #
    def not_found?
      404 == @code
    end

    #
    # Base URI from the HTML doc head element
    # http://www.w3.org/TR/html4/struct/links.html#edef-BASE
    #
    def base
      @base = if doc
        href = doc.search('//head/base/@href')
        URI(href.to_s) unless href.nil? rescue nil
      end unless @base
      
      return nil if @base && @base.to_s().empty?
      @base
    end


    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    def to_abs(link)
      return nil if link.nil?

      # remove anchor
      link = URI.encode(URI.decode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))
      return nil if link.nil?
      if link =~ /^https?:\/\/[\S]+/
        #puts "keeper"
        #puts ""
        link
      elsif link =~ /^http?:\/\/[\S]+/
        #puts "keeper"
        #puts ""
        link
      elsif link =~ /^\/\//  
        #puts "should be tossed"
        #puts ""
      elsif link =~ /^\/\w/  
        #puts "should be absolute"
        #puts ""
        link = "#{@url.scheme}://#{@url.host}#{link}"
      elsif link =~ /^\w/  
        #puts "should be relative"
        #puts ""
        link = "#{@url.to_s}/#{link}"
      else
        #puts "im lost"
        #puts ""        
      end
      URI(link)
    end

    def to_absolute(link)
      return nil if link.nil?

      # remove anchor
      link = URI.encode(URI.decode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))

      relative = URI(link)
      absolute = base ? base.merge(relative) : @url.merge(relative)

      absolute.path = '/' if absolute.path.empty?

      return absolute
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?(uri)
      uri.host == @url.host
    end

    def marshal_dump
      [@url, @headers, @data, @body, @links, @code, @visited, @depth, @referer, @redirect_to, @response_time, @fetched]
    end

    def marshal_load(ary)
      @url, @headers, @data, @body, @links, @code, @visited, @depth, @referer, @redirect_to, @response_time, @fetched = ary
    end

    def to_hash
      {'url' => @url.to_s,
       'headers' => Marshal.dump(@headers),
       'data' => Marshal.dump(@data),
       'body' => @body,
       'links' => links.map(&:to_s), 
       'code' => @code,
       'visited' => @visited,
       'depth' => @depth,
       'referer' => @referer.to_s,
       'redirect_to' => @redirect_to.to_s,
       'response_time' => @response_time,
       'fetched' => @fetched}
    end

    def self.from_hash(hash)
      page = self.new(URI(hash['url']))
      {'@headers' => Marshal.load(hash['headers']),
       '@data' => Marshal.load(hash['data']),
       '@body' => hash['body'],
       '@links' => hash['links'].map { |link| URI(link) },
       '@code' => hash['code'].to_i,
       '@visited' => hash['visited'],
       '@depth' => hash['depth'].to_i,
       '@referer' => hash['referer'],
       '@redirect_to' => (!!hash['redirect_to'] && !hash['redirect_to'].empty?) ? URI(hash['redirect_to']) : nil,
       '@response_time' => hash['response_time'].to_i,
       '@fetched' => hash['fetched']
      }.each do |var, value|
        page.instance_variable_set(var, value)
      end
      page
    end

    def crawl
   	  @logger.info "Crawling url: #{url}"
      response = HTTParty.get(url, :verify => false)
      #puts response.body, response.code, response.message, response.headers.inspect      
      @body = response.body
      @code = response.code
    end

    def queue_links
      @logger.info "Q'ing links"
      links.delete_if{ |l| skip_link?(l) }
    end

    def save_categories
      @logger.info "Saving categories"

      @dir["sub_cat"]        = Array.new
      @dir["sub_cat_urls"]   = Array.new
      @dir["sub_cat_map"]    = Array.new  
      begin
        keys                 = doc.css("div.cat li a").map { |a| a[:href] }.flatten
        values               = doc.css("div.cat li a b").map { |a| a.children.map { |t| t.to_s } }.flatten
        zip_cats             = keys.zip(values)
      rescue
        logger.info "choked while extracting sub categories #{@url}"
      end

      @dir["sub_cat"]      = values
      @dir["sub_cat_urls"] = keys
      @dir["sub_cat_map"]  = zip_cats              
    end

    def save_sites
      @logger.info "Saving sites"

      @dir["sites"] = Array.new
      begin
        @dir["sites"] = doc.css("div.st li a").map { |a| { url: a[:href], site: a.children.to_s, description: strip_body(a.parent.text) } }.flatten
      rescue
        logger.info "choked while extracting sites #{@url}"
      end    
    end

    def strip_body(text)
      #text.gsub(/^\S+\n\n/, "").gsub(/$\n\S*\n/, "")
      text.gsub(/$\n\S*\n/, " ").sub("\n", " ")
    end

    def to_html
      @logger.info "to_html"
      FileUtils.mkdir_p @dir["location"]
      open("#{@dir["raw_html"]}", 'w') do |f|
        f.puts @body.to_ascii
      end              
    end

    def to_json
      @logger.info "to_json"
      FileUtils.mkdir_p @dir["location"]
      open("#{@dir["json_doc"]}", 'w') do |f|
        f.puts @dir.to_json
      end                      
    end

    def skip_link?(link)
      skip        = %r{^/thespark/}, %r{^/[Rr]egional/}, %r{^/new/}, %r{^/picks/}            
      skip.any? { |pattern| link.path =~ pattern }
    end  

    def save_unique_links(links)
    end

  end
end