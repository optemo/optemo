class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :continuous, :binary, :categorical, :binarygroup, :prefered, :utility # Caching of features' names
  cattr_accessor :prefDirection, :maximum, :minimum, :utility_weight, :cluster_weight  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some attribute globals
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups, :extendednav  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :category_id

  def initialize (url = nil)
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    self.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, I highly suspect that setting this to false breaks the application.
    self.relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    self.numGroups = 9
    self.extendednav = false
    self.prefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
    self.maximum = Hash.new
    self.minimum = Hash.new
    self.continuous = Hash.new{|h,k| h[k] = []}
    self.binary = Hash.new{|h,k| h[k] = []}
    self.categorical = Hash.new{|h,k| h[k] = []}
    self.binarygroup = Hash.new{|h,k| h[k] = []}
    self.prefered = Hash.new{|h,k| h[k] = []}
    self.utility = Hash.new{|h,k| h[k] = []}     
    self.utility_weight = Hash.new(1)
    self.cluster_weight = Hash.new(1)

    # file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
    # file.each_pair do |product_type,d|
    #   if d["url"].keys.include? url
    #     self.product_type = product_type
    #     break
    #   end
    # end
    # self.product_type ||= 'camera_bestbuy' #Default product type
    p_url = nil
    ProductTypeUrl.find_each do |u|
      if u.url.include? url
        p_url = u
        break
      end
    end
    p_url ||= ProductTypeUrl.find_by_product_type('camera_bestbuy').first

    self.product_type = p_url.product_type.name
    p_type = p_url.product_type

    # product_yml = file[self.product_type]
    # self.category_id = product_yml["category_id"]
    self.category_id = p_type.category_id.split(',').map{ |id| id.to_i }
    
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false
    # self.directLayout = product_yml["layout"] == "direct"
    # self.mobileView = product_yml["layout"] == "mobileview"
    self.directLayout = p_type.layouts.split(',').map{ |l| l.strip }.include?("direct")
    self.mobileView = p_type.layouts.split(',').map{ |l| l.strip }.include?("mobileview")

    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.
    # self.piwikSiteId = product_yml["url"][url] || 10 # This is a catch-all for testing sites.
    self.piwikSiteId = p_url.weight || 10 # This is a catch-all for testing sites.

        # This block gets out the continuous, binary, and categorical features
    p_headings = ProductTypeHeading.find_all_by_product_type_id(p_type.id, :include => :product_type_features) # eager loading headings and features to reduce the queries.
    p_headings.each do |heading|
      heading.product_type_features.each do |feature|
        used_fors = feature.used_for.split(',').map { |uf| uf.strip }
        case feature.feature_type
        when "Continuous"
            used_fors.each{|flag| self.continuous[flag] << feature.name}
          self.continuous["all"] << feature.name #Keep track of all features
          self.prefDirection[feature.name] = feature.prefdir ? 1 : -1
          self.maximum[feature] = feature.max if feature.max > 0
          self.minimum[feature] = feature.min if feature.min > 0
        when "Binary"
          used_fors.each{|flag| self.binary[flag] << feature.name; self.binarygroup[heading.name] << feature.name if flag == "filter"}
          self.binary["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
        when "Categorical"
          used_fors.each{|flag| self.categorical[flag] << feature.name}
          self.categorical["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
        end
         self.utility_weight[feature.name] = feature.utility if feature.utility > 1
         self.utility["all"] << feature.name if feature.utility > 1
         self.cluster_weight[feature.name] = feature.cluster if feature.cluster > 1
      end
    end
  
    # # This block gets out the continuous, binary, and categorical features
    # product_yml["specs"].each_pair do |heading, specs|
    #   specs.each_pair do |feature,atts|
    #     case atts["type"]
    #     when "Continuous"
    #       atts["used_for"].each{|flag| self.continuous[flag] << feature}
    #       self.continuous["all"] << feature #Keep track of all features
    #       self.prefDirection[feature] = atts["prefdir"] if atts["prefdir"]
    #       self.maximum[feature] = atts["max"] if atts["max"]
    #       self.minimum[feature] = atts["min"] if atts["min"]
    #       self.continuous["sortby"].each_index{|i|  self.continuous["sortby"][i] ||= "#{self.continuous["sortby"][i]}_factor"} 
    #     when "Binary"
    #       atts["used_for"].each{|flag| self.binary[flag] << feature; self.binarygroup[heading] << feature if flag == "filter"}
    #       self.binary["all"] << feature #Keep track of all features
    #     when "Categorical"
    #       atts["used_for"].each{|flag| self.categorical[flag] << feature}
    #       self.categorical["all"] << feature #Keep track of all features
    #       self.prefered[feature] = atts["prefered"] if atts["prefered"]
    #     end
    #      self.utility_weight[feature] = atts["utility"] if atts["utility"]
    #      self.cluster_weight[feature] = atts["cluster"] if atts["cluster"]
    #   end
     
    # end
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
end
