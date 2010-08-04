class Session
  # This is probably no longer needed
  #  def initialize (id, version)
  #		@id = id
  #		@version = version
  #	end

  # products.yml gets parsed below in load_defaults() and initializes these variables.
  attr_accessor :version, :id, :search  # Basic individual data
  attr_accessor :directLayout, :lineItemView  # View choice (Assist vs. Direct)
  attr_accessor :continuous, :binary, :categorical  # Caching of features' names
  attr_accessor :prefDirection, :maximumPrice, :minimumPrice  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some price globals
  attr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups  # These flags should probably be stripped back out of the code eventually
  attr_accessor :product_type # Product type (camera_us, etc.), used everywhere

  def searches
    # Return searches with this session id
    Search.find_all_by_session_id(@id)
  end

  def self.current
    @@current
  end
  
  def self.current=(s)
    @@current = s
  end
  
  def self.load_defaults(url)
    defaultSite = 'printers.browsethenbuy.com'
    s = Session.current = Session.new
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    s.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, I highly suspect that setting this to false breaks the application.
    s.relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    s.numGroups = 9
    # Boostexter labels could theoretically be turned on and off by this switch. Not currently used. In the past, this was in GlobalDeclarations.rb
    # s.boostexterLabels = true
    
    s.prefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction

    s.continuous = Hash.new{|h,k| h[k] = []}
    s.binary = Hash.new{|h,k| h[k] = []}
    s.categorical = Hash.new{|h,k| h[k] = []}
    file = YAML::load(File.open("#{RAILS_ROOT}/config/products.yml"))
    url = defaultSite if file[url].blank?
    product_yml = file[url]
    s.product_type = product_yml["product_type"].first
    # This block gets out the continuous, binary, and categorical features
    product_yml.each do |feature,stuff| 
      type = stuff.first
      flags = stuff.second
      case type
      when "Continuous"
        flags.each{|flag| s.continuous[flag] << feature}
        options = stuff.third
        s.prefDirection[feature] = options["prefdir"] if options && options["prefdir"]
      when "Binary"
        flags.each{|flag| s.binary[flag] << feature}
      when "Categorical"
        flags.each{|flag| s.categorical[flag] << feature}
      end
      s.continuous["all"] = []
      s.binary["all"] = []
      s.categorical["all"] = []
      product_yml.each{|feature,stuff| s.continuous["all"] << feature if stuff.first == "Continuous"}
      product_yml.each{|feature,stuff| s.binary["all"] << feature if stuff.first == "Binary"}
      product_yml.each{|feature,stuff| s.categorical["all"] << feature if stuff.first == "Categorical"}

      # lineItemView forces the use of the .lv CSS classes and renders the _listbox.html.erb partial instead of the _navbox.html.erb partial.
      # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
      # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
      s.lineItemView = product_yml["layout"].first == "lineview" unless product_yml.nil? || product_yml["layout"].nil?
      s.directLayout = product_yml["layout"].second == "simple" unless product_yml.nil? || product_yml["layout"].nil?
      # At the moment, these are used in product scraping only.
      if feature == "price"
        s.maximumPrice = stuff.fourth.values.first
        s.minimumPrice = stuff.fifth.values.first
      end
    end

    s.lineItemView ||= false #Default is grid view 
    s.directLayout ||= false #Default is Optemo Assist
    s
  end
  
  
  def self.isCrawler?(str)
    str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona/i)
  end
end
