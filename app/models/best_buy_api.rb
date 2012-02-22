class BestBuyApi
  require 'net/http'
  class RequestError < StandardError; end
  class FeedDownError < StandardError; end
  class << self
    BESTBUY_URL = "http://www.bestbuy.ca/api/v2"
    DEBUG = false
    
    #Find BestBuy products
    def product_search(id, includeall = true, english = true)
      q = english ? {} : {:lang => "fr"}
      q[:id] = id
      if includeall
        q[:include] = "all"
      end
      cached_request('product',q)
      # From the BestBuy API documentation, use &Include=media and/or any of the following: 
      # relations,description,availability,all (in comma-separated format as a URL parameter)
    end
    
    def product_reviews(id)
      cached_request('reviews',{:id=>id})
    end
    
    #Search through the  Categories
    def category_search(id)
      cached_request('category',{:id => id})
    end
    
    def get_subcategories(id, english = true)
      
      q = english ? {:lang => "en"} : {:lang => "fr"}
      q[:id] = id
      subcats = {}
      #puts "#{q}"
      res = cached_request('category',q)  
        children = res["subCategories"].inject([]){|children, sc| children << {sc["id"] => sc["name"]}}
        subcats = {{res["id"] => res["name"]} => children}  
    
      subcats
    end
    
    #Find all the products in a category
    def listing(id,page=1)
      cached_request('search',{:page => page, :categoryid => id})
    end
    
    def some_ids(id)
      #This can accept an array or a single id
      id = [id] unless id.class == Array
      id = id[0..0] if Rails.env.test? #Only check first category for testing
      ids = []
      id.each do |my_id|
        res = cached_request('search',{:page => 1,:categoryid => my_id, :sortby => "name", :pagesize => 10})
        ids += res["products"].map{|p|BBproduct.new(:id => p["sku"], :category => my_id)}
      end
       #puts "#{ids.to_s}"
       ids
    end
    
    def category_ids(id)
      #This can accept an array or a single id
      id = [id] unless id.class == Array
      id = id[0..0] if Rails.env.test? #Only check first category for testing
      ids = []
      id.each do |my_id|
        page = 1
        totalpages = nil
        while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
          res = cached_request('search',{:page => page,:categoryid => my_id, :sortby => "name"})
          totalpages ||= res["totalPages"]
          ids += res["products"].map{|p|BBproduct.new(:id => p["sku"], :category => my_id)}
          page += 1
          #sleep 1 No need for waiting
        end
      end
      ids
    end
    
    def search(string,page=1)
      cached_request('search',{:page => page,:name => string})
    end
    
    def keyword_search(query)
      
        page = 1
        totalpages = nil
        skus = []
       # while (page == 1 || page <= totalpages && !Rails.env.test?) #Only return one page in the test environment
          res = cached_request('search',{:page => page,:query => query, :sortby => "name", :pagesize=> 100})
         # totalpages ||= res["totalPages"]
          skus += res["products"].inject([]){|sks, ele| sks << ele["sku"] }
       #   page += 1
       # end
      skus
    end

    def cached_request(type, params = {})
      #Data is only valid for 1 hour
      CachingMemcached.cache_lookup(type + params.to_s + Time.now.strftime("%Y-%m-%d-%H")) do
        send_request(type, params)
      end
    end

    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def send_request(type,params)
      request_url = prepare_url(type,params)
      log "Request URL: #{request_url}"
      res = Net::HTTP.get_response(URI::parse(request_url))
      #puts "#{res.body}"
      unless res.kind_of? Net::HTTPSuccess
        #if res.code == 302
        #  raise BestBuyApi::FeedDownError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #else
          raise BestBuyApi::RequestError, "HTTP Response: #{res.code} #{res.message} for #{request_url}"
        #end
      end
      begin
        JSON.parse(res.body)
      rescue JSON::ParserError
        raise BestBuyApi::RequestError, "Bad Response: JSON Parser Error for #{request_url}"
      end
      
    end
    
    protected
      def log(s)
        return unless DEBUG
        if defined? Rails.logger
          Rails.logger.error(s)
        elsif defined? LOGGER
          LOGGER.error(s)
        else
          puts s
        end
      end
      
    private 
      def prepare_url(type, params)
        qs = '' #options
        qf = '' #filters
        sf = '' #store filters
        params.each {|k,v|
          next unless v && k != :id
          v = v.join(',') if v.is_a? Array
          qs << "&#{k.to_s}=#{URI.encode(v.to_s)}"
        }
        if params[:id]
            "#{BESTBUY_URL}/json/#{type}/#{params[:id]}?#{qs}"
        else
            "#{BESTBUY_URL}/json/#{type}?#{qs}"
        end
      end
   end
end