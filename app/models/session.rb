class Session
  # products.yml gets parsed below, initializing these variables.
  attr_accessor :version, :id, :search  # Basic individual data. These are not set in initialization.
  attr_accessor :directLayout, :lineItemView  # View choice (Assist vs. Direct)
  attr_accessor :continuous, :binary, :categorical  # Caching of features' names
  attr_accessor :prefDirection, :maximumPrice, :minimumPrice  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some price globals
  attr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups  # These flags should probably be stripped back out of the code eventually
  attr_accessor :product_type # Product type (camera_us, etc.), used everywhere

  def initialize (url)
    defaultSite = 'printers.browsethenbuy.com'
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    @dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, I highly suspect that setting this to false breaks the application.
    @relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    @numGroups = 9
    # Boostexter labels could theoretically be turned on and off by this switch. Not currently used. In the past, this was in GlobalDeclarations.rb
    # s.boostexterLabels = true
    
    @prefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction

    @continuous = Hash.new{|h,k| h[k] = []}
    @binary = Hash.new{|h,k| h[k] = []}
    @categorical = Hash.new{|h,k| h[k] = []}
    file = YAML::load(File.open("#{RAILS_ROOT}/config/products.yml"))
    url = url.split(".")[-2..-1].join(".") if file[url].blank? # If no www.laserprinterhub.com, try laserprinterhub.com
    url = defaultSite if file[url].blank?
    product_yml = file[url]
    @product_type = product_yml["product_type"].first
    # This block gets out the continuous, binary, and categorical features
    product_yml.each do |feature,stuff| 
      type = stuff.first
      flags = stuff.second
      case type
      when "Continuous"
        flags.each{|flag| @continuous[flag] << feature}
        options = stuff.third
        @prefDirection[feature] = options["prefdir"] if options && options["prefdir"]
      when "Binary"
        flags.each{|flag| @binary[flag] << feature}
      when "Categorical"
        flags.each{|flag| @categorical[flag] << feature}
      end
      @continuous["all"] = []
      @binary["all"] = []
      @categorical["all"] = []
      product_yml.each{|feature,stuff| @continuous["all"] << feature if stuff.first == "Continuous"}
      product_yml.each{|feature,stuff| @binary["all"] << feature if stuff.first == "Binary"}
      product_yml.each{|feature,stuff| @categorical["all"] << feature if stuff.first == "Categorical"}

      # lineItemView forces the use of the .lv CSS classes and renders the _listbox.html.erb partial instead of the _navbox.html.erb partial.
      # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
      # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
      @lineItemView = product_yml["layout"].first == "lineview" unless product_yml.nil? || product_yml["layout"].nil?
      @directLayout = product_yml["layout"].second == "simple" unless product_yml.nil? || product_yml["layout"].nil?
      # At the moment, these are used in product scraping only.
      if feature == "price"
        @minimumPrice = stuff.fourth.values.first
        @maximumPrice = stuff.fifth.values.first
      end
    end

    @lineItemView ||= false #Default is grid view 
    @directLayout ||= false #Default is Optemo Assist
    Session.current = self
	end

  def searches
    # Return searches with this session id
    Search.find_all_by_session_id(@id)
  end

  def lastsearch
    Search.find_last_by_session_id(@id)
  end

  def self.current
    @@current
  end
  
  def self.current=(s)
    @@current = s
  end

  def self.isCrawler?(str)
    str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona/i)
  end
end
