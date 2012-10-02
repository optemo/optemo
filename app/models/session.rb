class Session
  cattr_accessor :search  #The current search. This is a global pointer to it.
  cattr_accessor :product_type # The product type which is an integer hash of the current category_id plus retailer
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :features # Gets the feature customizations which allow the site to be configured
  cattr_accessor :quebec # Whether the current region was detected as Quebec, used for EHF
  cattr_accessor :landing_page # Preserve the landing page's product type in case product_type gets changed to a subcategory
  cattr_accessor :subcategory # Used to look up values of ranges by a subcategory under the product type

  def initialize (product_type = nil)
    self.product_type = product_type || ProductCategory.first.product_type
    self.landing_page = self.product_type
    self.subcategory = []
    self.features = Hash.new{|h,k| h[k] = []} #This get configured by the set_features function
  end
  
  def self.initialize_with_search(search)
    self.search = search
    self.subcategory = []
    selected_product_type = Maybe(search.userdatacats.select{|d| d.name == 'product_type'}.map{|d| d.value})
    if selected_product_type.length == 1
      # one subcategory selected, save its name for use in caching
      self.subcategory = search.userdatacats.select{|d| d.name == 'product_type'}
      if !Facet.find_by_product_type_and_used_for(selected_product_type.first, ['sortby','show','filter']).nil?
        # subcategory has its own facets, therefore, set product type to it
        new_product_type = selected_product_type.first
      else
        new_product_type = self.product_type
      end
      self.product_type = new_product_type
    end
    self.features = Hash.new{|h,k| h[k] = []} #This gets configured by the set_features function
    set_features([new_product_type])
  end
  
  def self.product_type_leaves
    ProductCategory.get_leaves(product_type)
  end
  
  def self.landing_page_leaves
    ProductCategory.get_leaves(landing_page)
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
    features["filter"].map{|f| f.name if f.feature_type=="Continuous" && f.ui=="ranges"}.compact
  end
  
  def self.set_features(categories = [])
    # if an array of categories is given, dynamic features which apply only to those categories are shown
    facets = []
    if Session.subcategory.length == 1 and [Session.subcategory.first.value] != categories
      # correct the categories if passed in the parent category but a subcategory is selected
      categories = [Session.subcategory.first.value]
    end
    if categories.length == 1
      # set facets to those of given category if they exist and if not more than one subcategory selected
      facets = Facet.where(product_type: categories.first, active: true, used_for: ['filter','sortby','show'])
    end
    if facets.empty?
      # default to facets of landing page
      facets = Facet.where(product_type: Session.landing_page, active: true, used_for: ['filter','sortby','show'])
    end
    # initialize features to the facets, not including the dynamically excluded facets
    dynamically_excluded = []
    self.features = facets.includes(:dynamic_facets).order(:value).select do |f|
      #These are the subcategories for which this feature is only used for
      f.name = 'pricePlusEHF' if (f.name == 'saleprice' && Session.quebec)
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
