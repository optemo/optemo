class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups, :extendednav  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type, :product_type_int # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :category_id
  cattr_accessor :rails_category_id # This is passed in from ajaxsend and the logic for determining the category ID is from the javascript side rather than from the Rails side. Useful for embedding.
  cattr_accessor :Features # Gets out the features which include utility, comparison, filter, cluster, sortby, show   

  def initialize (cat_id = nil, request_url = nil)
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    self.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, setting this to false might breaks the application. - ZAT
    self.relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    self.numGroups = 9
    self.extendednav = false
    self.features = Hash.new{|h,k| h[k] = []} # Features include utility, comparison, filter, cluster, sortby, show
    
    # 2 is hard-coded to cameras at the moment and is the default
    # Check the product_types table for details
    p_type = ProductType.find(cat_id.blank? ? 2 : CategoryIdProductTypeMap.find_by_category_id(cat_id.to_i).product_type_id)
    self.product_type = p_type.name
    #Define an integer for the product type
    chars = []
    self.product_type.each_char{|c|chars << c.getbyte(0)*chars.size}
    self.product_type_int = chars.sum * -1
    
    self.category_id = p_type.category_id_product_type_maps.map{|x|x.category_id}
    
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false
    self.directLayout = p_type.layout.include?("direct")
    self.mobileView = p_type.layout.include?("mobileview")

    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.
    p_url = nil  # Initialize variable out here for locality
    p_type.urls.each do |u|
      p_url = u if request_url[u.url] 
    end
    p_url ||= p_type.urls.first
    self.piwikSiteId = p_url.piwik_id || 10 # This is a catch-all for testing sites.
  end

  def self.searches
    # Return searches with this session id
    Search.where(["session_id = ?",self.id])
  end

  def self.lastsearch
    Search.find_last_by_session_id(self.id)
  end

  def self.isCrawler?(str, esc_param)
    # esc_param is either nil (if it doesn't exist) or "" if it does. The reason is that the URL ends with ?_escaped_fragment_= (the value is empty).
    # For more information on esc_param and its purpose, see the file "lib/absolute_url_enabler.rb" 
    !esc_param.nil? || (!str.nil? && str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona|Java/i))
  end
  # Generic features after catogories used for search have been defined. This is called in function classVariables of compare controller
  def self.getFeatures(userdatacats)
    facets = Facet.find_all_by_product_type_id(p_type.id, :include=>:dynamic_facets)

    # Gets out the features which include utility, comparison, filter, cluster, sortby, show   
    facets.each do |f|
      temp = {:name=>f.name, :feature_type=>f.feature_type, :value=>f.value}
      unless f.dynamic_facets.nil?
        temp.merge! {:categories => f.dynamic_facets}
      end
      self.features[f.used_for] << temp
    end

    category_ids = Maybe(userdatacats).take_while{|d| d == 'category'}.map{|d| d.value}
    deleted_filters = []
    self.features.each_pair do |k, v|
      # Sort every feature by its value
      v.sortby!{|f| f[:value]}
      # Set dynamic features. Remove the dynamic filters which will not used 
      v.reject!{|x| x.has_key?(:categories) && !x[:categories].nil? && !x[:categories].any? {|e| category_ids.include? e && deleted_filters << x[:name]}} 
    end

    # Resign userdatacats, userdataconts and userdatabins variables of search
    if !deleted_filters.empty?
      Maybe(search).resign_userdatas(deleted_filters)
    end
  end
end
