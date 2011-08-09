class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :continuous, :binary, :categorical, :binarygroup, :prefered, :utility # Caching of features' names
  cattr_accessor :prefDirection, :maximum, :minimum, :utility_weight, :cluster_weight  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some attribute globals
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups, :extendednav  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type, :product_type_int # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :category_id, :dynamic_filter_cat, :dynamic_filter_cont, :dynamic_filter_bin, :filters_order
  cattr_accessor :rails_category_id # This is passed in from ajaxsend and the logic for determining the category ID is from the javascript side rather than from the Rails side. Useful for embedding.

  def initialize (cat_id = nil, request_url = nil)
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    self.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, setting this to false might breaks the application. - ZAT
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
    self.dynamic_filter_cat = Hash.new{|h,k| h[k] = []}     
    self.dynamic_filter_cont = Hash.new{|h,k| h[k] = []}     
    self.dynamic_filter_bin = Hash.new{|h,k| h[k] = []}
    self.filters_order = Array.new
    
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
   
    continuous_filter_unsorted=[]
    binary_filter_unsorted=[]
    categorical_filter_unsorted=[]
    
    # This block gets out the continuous, binary, and categorical features
    p_headings = Heading.find_all_by_product_type_id(p_type.id, :include => :features) # eager loading headings and features to reduce the queries.
    p_headings.each do |heading|
      heading.features.each do |feature|
        cats = []
        cats = feature.used_for_categories.split(',') unless feature.used_for_categories.nil?

        cats.map{|c| c=c.strip}.each do |c|
          case feature.feature_type
          when "Continuous"
            self.dynamic_filter_cont[c] << feature.name
          when "Binary"
            self.dynamic_filter_bin[c] << feature.name
          when "Categorical"
            self.dynamic_filter_cat[c] << feature.name
          end
        end
        used_fors = feature.used_for.split(',').map { |uf| uf.strip }
        case feature.feature_type
        when "Continuous"
          self.continuous["all"] << feature.name #Keep track of all features
          self.prefDirection[feature.name] = feature.larger_is_better ? 1 : -1
          self.maximum[feature] = feature.max if feature.max > 0
          self.minimum[feature] = feature.min if feature.min > 0
          used_fors.each do |flag|
            if flag != 'filter' # filter is depents by category id, which maybe depents with last search condition, we can not do filter here
              self.continuous[flag] << feature.name
            end
          end

        #  self.continuous["sortby"] = ["saleprice_factor", "saleprice_factor_high", "orders_factor", "displayDate"]
          #self.continuous["sortby"].each_index{|i|  self.continuous["sortby"][i] = "#{self.continuous["sortby"][i]}_factor" unless self.continuous["sortby"][i].include?("factor")} 
        when "Binary"
          self.binary["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
          used_fors.each do |flag|
            if flag != 'filter' # only add features of selected product types to the filter
              self.binary[flag] << feature.name
            end
          end

        when "Categorical"
          self.categorical["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
          used_fors.each do |flag|
            if flag != 'filter' # only add features of selected product types to the filter
              self.categorical[flag] << feature.name
            end
          end

        end
         self.utility_weight[feature.name] = feature.utility_weight if feature.utility_weight > 1
         self.utility["all"] << feature.name if feature.utility_weight > 1
         self.cluster_weight[feature.name] = feature.cluster_weight if feature.cluster_weight > 1
      end
    end
    self.continuous['filter'] = continuous_filter_unsorted.sort {|a,b| a[1] <=> b[1]}.map{ |f| f[0] }
    self.binary['filter'] = binary_filter_unsorted.sort {|a,b| a[1] <=> b[1]}.map{|f| f[0] }
    self.categorical['filter'] = categorical_filter_unsorted.sort {|a,b| a[1] <=> b[1]}.map{|f| f[0] }
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
  # The logic is:
  # 1. if no categories have been selected, only show filters without used_for_categories.
  # 2. Any categories selected, filters without used_for_categories or categories selected included in used_for_categories
  def self.is_feature_in_myfilter_categories? (feature, myfilter_categories)
    ret = false
    if feature.used_for_categories.blank?
      ret = true
    else
      if myfilter_categories.size > 0
        cats = feature.used_for_categories.split(',')
        cats.each do |cat|
          cat = cat.strip
          if myfilter_categories.include? cat
            ret = true
            break
          end
        end
      end
    end
    ret
  end
  
  def self.getFilters(userdatacats)
    category_ids = []
    unless userdatacats.nil?
      userdatacats.each do |d|
        category_ids << d.value if d.name == 'category'
      end
    end
    
    # This block gets out the continuous, binary, and categorical features
    
    p_headings = Heading.find_all_by_product_type_id(ProductType.find_all_by_name(product_type).first.id, :include => :features) # eager loading headings and features to reduce the queries.
    p_headings.each do |heading|
      heading.features.each do |feature|
#        used_fors = feature.used_for.split(',').map { |uf| uf.strip }
        case feature.feature_type
        when "Continuous"
          if !feature.used_for.blank? && feature.used_for.include?('filter')
            if is_feature_in_myfilter_categories?(feature, category_ids)
              self.continuous['filter'] << feature.name 
              self.filters_order << {:name => feature.name, :filter_type=> 'cont', :show_order => feature.used_for_order}
            end
          end
        when "Binary"
          if !feature.used_for.blank? && feature.used_for.include?('filter') # only add features of selected product types to the filter
            if is_feature_in_myfilter_categories?(feature, category_ids) && feature.has_products
              self.binary['filter'] << feature.name
              self.binarygroup[heading.name] << feature.name unless self.binarygroup[heading.name].include? feature.name
              self.filters_order << {:name => heading.name, :filter_type =>  'bin', :show_order => heading.show_order} unless self.filters_order.index {|x| x[:name] == heading.name}
            end
          end
        when "Categorical"
          if !feature.used_for.blank? && feature.used_for.include?('filter') # only add features of selected product types to the filter
            if is_feature_in_myfilter_categories?(feature, category_ids)
              self.categorical['filter'] << feature.name 
              self.filters_order << {:name => feature.name, :filter_type => 'cat', :show_order => feature.used_for_order}
            end
          end
        end
      end
    end
    self.continuous["sortby"] = ["saleprice_factor", "orders_factor", "displayDate"]
    self.filters_order.sort_by! {|item| item[:show_order].to_i }
  end
end
