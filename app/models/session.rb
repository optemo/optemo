class Session
  cattr_accessor :search  #The current search. This is a global pointer to it.
  cattr_accessor :product_type # The product type which is an integer hash of the current category_id plus retailer
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :features # Gets the feature customizations which allow the site to be configured
  cattr_accessor :ranges # Uses ranges for continuous data instead of sliders

  def initialize (product_type = ProductCategory.first.product_type)
    self.product_type = product_type
    self.features = Hash.new{|h,k| h[k] = []} #This get configured by the set_features function
  end
  
  def self.product_type_leaves(ptype = product_type)
    ProductCategory.get_leaves(ptype)
  end
  
  def self.product_type_ancestors(ptype = product_type ,level =nil)
    ProductCategory.get_ancestors(ptype,level)
  end
  
  def self.product_type_subcategory(ptype=product_type)
     ProductCategory.get_subcategories(ptype)
  end
  def self.product_type_branch
    ProductCategory.get_ancestors(product_type)+[product_type]+ProductCategory.get_children(product_type)
  end
  
  def self.retailer
    product_type[0]
  end
  
  def self.feed_id
    product_type[1..-1]
  end
  
  def self.set_features(categories = [])
    #if an array of categories is given, dynamic features which apply only to those categories are shown
    dynamically_excluded = []
    # initialize features
    self.features = Facet.where("product_type= ?", product_type).includes(:dynamic_facets).order(:value).select do |f|
      #These are the subcategories for which this feature is only used for
      subcategories = f.dynamic_facets.map{|x|x.category}
      subcategories.empty? || #We don't store subcategories for features which are always used
      subcategories.any?{|e| categories.include? e} ||
      (dynamically_excluded << f && false) #If a feature is not selected, we need to note this
    end.group_by(&:used_for)
   
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
