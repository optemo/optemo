class Session
  # products.yml gets parsed below, initializing these variables.
  attr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  attr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  attr_accessor :continuous, :binary, :categorical  # Caching of features' names
  attr_accessor :prefDirection, :maximum, :minimum  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some attribute globals
  attr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups  # These flags should probably be stripped back out of the code eventually
  attr_accessor :product_type # Product type (camera_us, etc.), used everywhere
  attr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.

  def initialize (url = nil)
    defaultSite = 'printers.assist.demo.optemo.com'
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
    @maximum = Hash.new
    @minimum = Hash.new
    @continuous = Hash.new{|h,k| h[k] = []}
    @binary = Hash.new{|h,k| h[k] = []}
    @categorical = Hash.new{|h,k| h[k] = []}
    file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
    if url && file[url].blank? # If no www.laserprinterhub.com, try laserprinterhub.com
      split_url = url.split(".")[-2..-1]
      url = split_url.join(".") if split_url
    end
    url = defaultSite if file[url].blank?
    
    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.
    case url
    when 'printers.browsethenbuy.com' then @piwikSiteId = 2
    when 'cameras.browsethenbuy.com' then @piwikSiteId = 4
    when 'laserprinterhub.com', 'www.laserprinterhub.com' then @piwikSiteId = 6
    when 'm.browsethenbuy.com' then @piwikSiteId = 8
    else @piwikSiteId = 10 # This is a catch-all for testing sites. All other sites must be explicitly declared.
    end
    
    product_yml = file[url]
    @product_type = product_yml["product_type"]
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false
    @directLayout = product_yml["layout"] == "lineview"
    @mobileView = product_yml["layout"] == "mobileview"
    # This block gets out the continuous, binary, and categorical features
    product_yml.each do |feature,atts|
      case atts["feature_type"]
      when "Continuous"
        atts["used_for"].each{|flag| @continuous[flag] << feature}
        @continuous["all"] << feature #Keep track of all features
        @prefDirection[feature] = atts["prefdir"] if atts["prefdir"]
        @maximum[feature] = atts["max"] if atts["max"]
        @minimum[feature] = atts["min"] if atts["min"]
      when "Binary"
        atts["used_for"].each{|flag| @binary[flag] << feature}
        @binary["all"] << feature #Keep track of all features
      when "Categorical"
        atts["used_for"].each{|flag| @categorical[flag] << feature}
        @categorical["all"] << feature #Keep track of all features
      end
    end

    Session.current = self
	end

  def searches
    # Return searches with this session id
    Search.where(["session_id = ?",@id])
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

  def self.isCrawler?(str, esc_param)
    # esc_param is either nil (if it doesn't exist) or "" if it does. The reason is that the URL ends with ?_escaped_fragment_= (the value is empty).
    # For more information on esc_param and its purpose, see the file "lib/absolute_url_enabler.rb" 
    !esc_param.nil? || str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona/i)
  end
end
