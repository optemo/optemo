#--
# Copyright (c) 2009 Jan Ulrich, Optemo Technologies
# Copyright (c) 2006 Herryanto Siatono, Pluit Solutions
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'net/http'
require 'hpricot'
require 'cgi'

module BestBuy
  class RequestError < StandardError; end
  
  class Ecs
    BESTBUY_URL = "http://api.remix.bestbuy.com/v1"
    
    attr_writer :options # Default search options
    attr_writer :debug # debug flag
    
    #supply your apiKey
    def initialize(apiKey = '***REMOVED***', pid = '***REMOVED***')
      @options = {:apiKey => apiKey, :PID => pid}
      @debug = false
    end
    
    def self.configure(&proc)
      raise ArgumentError, "Block is required." unless block_given?
      yield @options
    end
    
    #Find BestBuy products
    def product_search(opts)
      if opts && opts[:category]
        opts[:"categoryPath.name"] = opts[:category]
        opts.delete(:category)
      end
      if opts[:postalCode]
        send_request('products+stores',opts)
      else
        send_request('products',opts)
      end
    end
    
    #Search through the BestBuy Categories
    def category_search(name)
      send_request('categories',{:name => name})
    end
    
    #Find store info
    def store_search(opts)
      send_request('stores',opts)
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,opts,page=1)
      raise BestBuy::RequestError, "No apiKey specified in options" if @options[:apiKey].nil?
      @options[:page] = page
      request_url = prepare_url(type,@options,opts)
      log "Request URL: #{request_url}"
      res = Net::HTTP.get_response(URI::parse(request_url))
      unless res.kind_of? Net::HTTPSuccess
        if res.body.index(/too many product matches/)
          raise BestBuy::RequestError, "Sorry, there are too many product matches (> 101).  Please narrow your query."
        else
          raise BestBuy::RequestError, "HTTP Response: #{res.code} #{res.message}"
        end
      end
      Response.new(res.body,type,opts, self)
    end

    # Response object returned after a REST call to Amazon service.
    class Response
      # XML input is in string format
      def initialize(xml, type, opts, ecs)
        @doc = Hpricot.XML(xml)
        @type = type #kept for generating the next results
        @opts = opts #kept for generating the next results
        @ecs = ecs
      end

      # Return Hpricot object.
      def doc
        @doc
      end

      ## Return true if request is valid.
      #def is_valid_request?
      #  (@doc/"isvalid").inner_html == "True"
      #end
      #
      ## Return true if response has an error.
      #def has_error?
      #  !(error.nil? || error.empty?)
      #end
      #
      ## Return error message.
      #def error
      #  Element.get(@doc, "error/message")
      #end
      
      # Return an array of Amazon::Element item objects.
      def items
        unless @items
          @items = (@doc/"product").collect {|item| Element.new(item)}
        end
        @items
      end
      
      # Returns the page of results as a Response object
      def next_results
        return nil if item_page >= total_pages
        @ecs.send_request(@type,@opts,item_page+1)
      end
      
      # Return current page no if :item_page option is when initiating the request.
      def item_page
        unless @item_page
          @item_page = (@doc/'products').first.attributes['currentPage'].to_i
        end
        @item_page
      end

      # Return total results.
      def total_results
        unless @total_results
          @total_results = (@doc/'products').first.attributes['total'].to_i
        end
        @total_results
      end
      
      # Return total pages.
      def total_pages
        unless @total_pages
          @total_pages = (@doc/'products').first.attributes['totalPages'].to_i
        end
        @total_pages
      end
    end
    
    protected
      def log(s)
        return unless @debug
        if defined? Rails.logger
          Rails.logger.error(s)
        elsif defined? LOGGER
          LOGGER.error(s)
        else
          puts s
        end
      end
      
    private 
      def prepare_url(type, opts, filters)
        qs = '' #options
        qf = '' #filters
        sf = '' #store filters
        opts.each {|k,v|
          next unless v
          v = v.join(',') if v.is_a? Array
          qs << "&#{k.to_s}=#{URI.encode(v.to_s)}"
        }
        filters.each {|k,v|
          next unless v
          if v.is_a? Array
            v = ' in('+v.join(',')+')' 
          else
            v = "'"+v.to_s+"'"
          end
          q = "&#{k.to_s}#{'=' if v.match(/^'\w/)}#{URI.encode(v.to_s)}"
          if type == "products+stores" && k.to_s.index(/#{store_attrs.join('|')}$/) == 0
            sf << q
          else
            qf << q
          end
        } unless filters.nil?
        if type == "products+stores"
            "#{BESTBUY_URL}/products#{('('+qf[1..-1]+')'if qf.length>1).to_s}+stores#{('('+sf[1..-1]+')'if sf.length>1).to_s}?#{qs[1..-1]}" #Search for products in certain stores
        else
          if filters.nil? || qf.length < 1
            "#{BESTBUY_URL}/#{type}?#{qs[1..-1]}"
          else
            "#{BESTBUY_URL}/#{type}(#{qf[1..-1]})?#{qs[1..-1]}" #Filter the search
          end
        end
      end
      
      def store_attrs
        unless @store_attrs
          req = Ecs.new(@options[:apiKey], @options[:PID])
          res = req.store_search(:postalCode => '75244')
          @store_attrs = (res.doc/'store>').map{|a|a.name}.delete_if{|a|a=="\n"}
        end
        @store_attrs
      end
  end

  # Internal wrapper class to provide convenient method to access Hpricot element value.
  class Element
    # Pass Hpricot::Elements object
    def initialize(element)
      @element = element
    end

    # Returns Hpricot::Elments object    
    def elem
      @element
    end
    
    # Find Hpricot::Elements matching the given path. Example: element/"author".
    def /(path)
      elements = @element/path
      return nil if elements.size == 0
      elements
    end
    
    # Find Hpricot::Elements matching the given path, and convert to Amazon::Element.
    # Returns an array Amazon::Elements if more than Hpricot::Elements size is greater than 1.
    def search_and_convert(path)
      elements = self./(path)
      return unless elements
      elements = elements.map{|element| Element.new(element)}
      return elements.first if elements.size == 1
      elements
    end

    # Get the text value of the given path, leave empty to retrieve current element value.
    def get(path='')
      Element.get(@element, path)
    end
    
    # Get the unescaped HTML text of the given path.
    def get_unescaped(path='')
      Element.get_unescaped(@element, path)
    end
    
    # Get the array values of the given path.
    def get_array(path='')
      Element.get_array(@element, path)
    end

    # Get the children element text values in hash format with the element names as the hash keys.
    def get_hash(path='')
      Element.get_hash(@element, path)
    end

    # Similar to #get, except an element object must be passed-in.
    def self.get(element, path='')
      return unless element
      result = element.at(path)
      result = result.inner_html if result
      result
    end
    
    # Similar to #get_unescaped, except an element object must be passed-in.    
    def self.get_unescaped(element, path='')
      result = get(element, path)
      CGI::unescapeHTML(result) if result
    end

    # Similar to #get_array, except an element object must be passed-in.
    def self.get_array(element, path='')
      return unless element
      
      result = element/path
      if (result.is_a? Hpricot::Elements) || (result.is_a? Array)
        parsed_result = []
        result.each {|item|
          parsed_result << Element.get(item)
        }
        parsed_result
      else
        [Element.get(result)]
      end
    end

    # Similar to #get_hash, except an element object must be passed-in.
    def self.get_hash(element, path='')
      return unless element
    
      result = element.at(path)
      if result
        hash = {}
        result = result.children
        result.each do |item|
          hash[item.name.to_sym] = item.inner_html
        end 
        hash
      end
    end
    
    def to_s
      elem.to_s if elem
    end
  end
end