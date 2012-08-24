class Session
  cattr_accessor :search  #The current search. This is a global pointer to it.
  cattr_accessor :product_type # The product type which is an integer hash of the current category_id plus retailer
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :features # Gets the feature customizations which allow the site to be configured
  cattr_accessor :quebec

  def initialize (product_type = nil)
    self.product_type = product_type || ProductCategory.first.product_type
    self.features = Hash.new{|h,k| h[k] = []} #This get configured by the set_features function
  end
  
  def self.initialize_product_type(product_type)
    product_type = product_type || ProductCategory.first.product_type
    # If no facets are defined for a (sub)category, set the product type as the parent instead to get the parent's layout
    product_type = Maybe(ProductCategory.get_parent(product_type).first) if Facet.where(product_type: product_type, active: true).empty?
    self.product_type = product_type
    self.features = Hash.new{|h,k| h[k] = []} #This get configured by the set_features function
  end
  
  def self.effective_product_type
    counts = CatSpec.count_current("product_type")
    if counts.keys.length == 1
      [counts.keys.first]
    else
      ProductCategory.get_ancestors(counts.keys)
    end
  end
  
  def self.product_type_leaves
    ProductCategory.get_leaves(product_type)
  end
  
  def self.retailer
    product_type[0]
  end
  
  def self.futureshop?
    product_type[0] == "F"
  end
  
  def self.bestbuy?
    product_type[0] == "B"
  end
  
  def self.amazon?
    product_type[0] == "A"
  end
  
  def self.feed_id
    product_type[1..-1]
  end
  
  def self.range_filters
    #Hard-coding EHF price lookup
    features["filter"].map{|f| f.name if f.feature_type=="Continuous" && f.ui=="ranges"}.compact << "pricePlusEHF"
  end
  
  def self.set_features(categories = [])
    # if an array of categories is given, dynamic features which apply only to those categories are shown
    # If there's 1 product subcategory selected, get its display facets if any, otherwise, get facets of the current product type
    facets = []
    if categories.length == 1
      facets = Facet.where(product_type: categories.first, active: true, used_for: ['filter','sortby','show'])
    end
    facets = Facet.where(product_type: product_type, active: true, used_for: ['filter','sortby','show']) if facets.empty?
    # initialize features to the facets, not including the dynamically excluded facets
    dynamically_excluded = []    
    self.features = facets.includes(:dynamic_facets).order(:value).select do |f|
      #These are the subcategories for which this feature is only used for
      subcategories = f.dynamic_facets.map{|x|x.category}
      subcategories.empty? || #We don't store subcategories for features which are always used
      subcategories.any?{|e| categories.include? e} ||
      (dynamically_excluded << f && false) #If a feature is not selected, we need to note this
    end.group_by{|x|x.used_for}
    # Some filters of last search need to be removed when dynamic filters removed
    unless categories.empty?
      dynamically_excluded.each do |f|
        selection = case f.feature_type
          when "Continuous" then self.search.userdataconts
          when "Categorical" then self.search.userdatacats
          when "Binary" then self.search.userdatabins
        end
        Maybe(selection.select{|ud|ud.name == f.name}.first).destroy
      end
    end
  end

  def self.isCrawler?(str, esc_param)
    # esc_param is either nil (if it doesn't exist) or "" if it does. The reason is that the URL ends with ?_escaped_fragment_= (the value is empty).
    # For more information on esc_param and its purpose, see the file "lib/absolute_url_enabler.rb" 
    !esc_param.nil? || (!str.nil? && str.match(/Google|msnbot|Rambler|Yahoo|AbachoBOT|accoona|AcioRobot|ASPSeek|CocoCrawler|Dumbot|FAST-WebCrawler|GeonaBot|Gigabot|Lycos|MSRBOT|Scooter|AltaVista|IDBot|eStyle|ScrubbyBloglines subscriber|Dumbot|Sosoimagespider|QihooBot|FAST-WebCrawler|Superdownloads Spiderman|LinkWalker|msnbot|ASPSeek|WebAlta Crawler|Lycos|FeedFetcher-Google|Yahoo|YoudaoBot|AdsBot-Google|Googlebot|Scooter|Gigabot|Charlotte|eStyle|AcioRobot|GeonaBot|msnbot-media|Baidu|CocoCrawler|Google|Charlotte t|Yahoo! Slurp China|Sogou web spider|YodaoBot|MSRBOT|AbachoBOT|Sogou head spider|AltaVista|IDBot|Sosospider|Yahoo! Slurp|Java VM|DotBot|LiteFinder|Yeti|Rambler|Scrubby|Baiduspider|accoona|Java/i))
  end

end
