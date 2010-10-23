class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins
  
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
  end

  ## Computes distributions (arrays of normalized product counts) for all continuous features 
  def distribution(feat)
       dist = Array.new(21,0)
       min = ContSpec.allMinMax(feat)[0]
       max = ContSpec.allMinMax(feat)[1]
       return [[],[]] if max.nil? || min.nil?
       current_dataset_minimum = max
       current_dataset_maximum = min
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       specs = ContSpec.cachemany(products, feat)
       specs.each do |s|
         current_dataset_minimum = s if s < current_dataset_minimum
         current_dataset_maximum = s if s > current_dataset_maximum
         i = ((s - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       [[current_dataset_minimum, current_dataset_maximum], round2Decim(normalize(dist))]
  end
  
  #Range of product offerings
  def ranges(featureName)
     @sRange ||= {}
     if @sRange[featureName].nil?
       min = clusters.map{|c|c.ranges(featureName)[0]}.compact.sort[0]
       max = clusters.map{|c|c.ranges(featureName)[1]}.compact.sort[-1] 
       @sRange[featureName] = [min, max]
     end
     @sRange[featureName]  
  end
  
  def indicator(featureName)
    indic = false
    values = clusters.map{|c| c.indicator(featureName)}
    if values.index(false).nil?
      indic = true
    end  
    indic
  end
  
  def relativeDescriptions
    s = Session.current
    return if clusters.empty?
    @reldescs ||= []
    if @reldescs.empty?
      feats = {}
      s.continuous["filter"].each do |f|
        norm = ContSpec.allMinMax(f)[1] - ContSpec.allMinMax(f)[0]
        norm = 1 if norm == 0
        feats[f] = clusters.map{ |c| c.representative}.compact.map {|c| c[f].to_f/norm } 
      end
      cluster_count.times do |i|
        dist = {}
        s.continuous["filter"].each do |f|
          if feats[f].min == feats[f][i]
            #This is the lowest feature
            distance = feats[f].sort[1] - feats[f][i]
            dist[f] = distance unless distance == 0 && feats[f].sort[2] == feats[f][i] #Remove ties
          elsif feats[f].max == feats[f][i]
            #This is the highest feature
            distance = feats[f][i] - feats[f].sort[-2]
            dist[f] = distance unless distance == 0 && feats[f].sort[-3] == feats[f][i] #Remove ties
          #elsif feats[f].sort[4] == feats[f][i]
          #  #This is an average feature
          #  dist[f] = ([feats[f].sort[4]-feats[f].sort[3],feats[f].sort[5]-feats[f].sort[4]].min) - 1
          #  dist[f] = distance unless distance == -1 #Remove ties
          end
        end if cluster_count > 1
        n = dist.count
        d = []
        dist.sort{|a,b| b[1] <=> a[1]}[0..1].each do |f,v|
          dir = feats[f].min == feats[f][i] ? "lower" : "higher"
          #dir = feats[f].min == feats[f][i] ? "lower" : feats[f].max == feats[f][i] ? "higher" : "avg"
          d << dir+f
        end
        #Add binary labels
        #d.unshift "Waterproof" if clusters[i].waterproof && layer == 1
        #d.unshift "SLR" if clusters[i].slr && layer == 1
        if d.empty?
          @reldescs << ["avg"]
        else
          @reldescs << d
        end
        #@descs[-1] = @descs.last + " (#{n})"
      end
    end
    @reldescs
  end
  
  def boostexterClusterDescriptions
    @returned_taglines ||= BoostexterRule.clusterLabels(clusters)
  end
  
  def clusterDescription(clusterNumber)
    return if clusters.empty?
    clusterDs = Array.new 
    des = []
    slr=0
      Session.current.binary["filter"].each do |f|
        if clusters[clusterNumber].indicator(f)
          (f=='slr' && indicator("slr"))? slr = 1 : slr =0
          des<< f if $config["DescFeatures"].include?(f) 
        end
      end
      
      Session.current.continuous["desc"].each do |f|
        if !(f == "opticalzoom" && slr == 1)
              cRanges = clusters[clusterNumber].ranges(f)
              if (cRanges[1] < ContSpec.allLow(f))
                 clusterDs << {'desc' => "low_"+f, 'stat' => 0}  
              elsif (cRanges[0] > ContSpec.allHigh(f))
                 clusterDs <<  {'desc' => "high_"+f, 'stat' => 2}  
              elsif ((cRanges[0] >= ContSpec.allLow(f)) && (cRanges[1] <= ContSpec.allHigh(f))) 
                  clusterDs <<  {'desc' => "avg_"+f, 'stat' => 1}
              end 
        end   
      end     
      
    clusterDs.sort!{|a,b| b['stat'] <=> a['stat']}
    clusterDs = clusterDs[0..1] if clusterDs.size > 2
    clusterDs[0] = {'desc' => "average", 'stat' => 1} if clusterDs.blank?
    des << clusterDs.map{|d| d['desc']};
  end
  
  def searchDescription
    des = []
    Session.current.continuous["desc"].each do |f|
      searchR = ranges(f)
      return ['Empty'] if searchR[0].nil? || searchR[1].nil?
      if (searchR[1] <= ContSpec.allLow(f))
           des <<  "low_#{f}"
      elsif (searchR[0] >= ContSpec.allHigh(f))
           des <<  "high_#{f}"
      end
    end  
    des[0..3]
  end
    
  def minimum(feature)
    feature = feature + "_min"
    min = clusters[0].send(feature)
    for i in 1..cluster_count-1
      min = clusters[i].send(feature) if clusters[i].send(feature) < min
    end
    min
  end
  
  def maximum(feature)
    feature = feature + "_max"
    max = clusters[0].send(feature)
    for i in 1..cluster_count-1
      max = clusters[i].send(feature) if clusters[i].send(feature) > max
    end
    max
  end
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def cluster
    @cluster ||= Cluster.new(products)
  end
  
  def initial_products(set_search_id=nil)
    s = Session.current
    #We probably need a better algorithm to check for collisions
    chars = []
    s.product_type.each_char{|c|chars<<c.getbyte(0)*chars.size}
    search_id = chars.sum*-1
    #This can be optimized not to check every time
    if SearchProduct.where(["search_id = ?", search_id]).limit(1).empty?
      SearchProduct.transaction do
        Product.valid.instock.map{|product| SearchProduct.new(:product_id => product.id, :search_id => search_id)}.each(&:save)
      end
    end
    SearchProduct.create(:product_id => -1, :search_id => set_search_id) if set_search_id
    search_id
  end
  
  def products_size
    @products_size ||= products.size
  end
  
  def products
    unless @products
      #selected_features = (userdataconts.map{|c| c.name+c.min.to_s+c.max.to_s}+userdatabins.map{|c| c.name+c.value.to_s}+userdatacats.map{|c| c.name+c.value}<<keyword_search).hash
      #@products =   CachingMemcached.cache_lookup("#{Session.current.product_type}Products#{selected_features}") do
        product_list = SearchProduct.where(filterquery).select(:product_id)
        product_list_ids = product_list.map(&:product_id)
        @products_size = product_list_ids.size
        utility_list = ContSpec.cachemany(product_list_ids, "utility")
        # Cannot avoid sorting, since this result is cached.
        # If there is an error here, you might need to run rake calculate_factors. (utility_list.length should match product_list.length)
         @products = utility_list.zip(product_list_ids).sort{|a,b|b[0]<=>a[0]}.map{|a,b|b}
    end
    @products
  end
  
  def filterquery
    s = Session.current
    fqarray = []
    #This might be able to be refactored into a single MySQL query
    if @myproducts
      if @myproducts == -1
        my_search = initial_products(id)
      else
        my_search = id
      end
    else
      s.searches.map(&:id).reverse.each do |s_id|
        next if s_id > id
        c = SearchProduct.where(["search_id = ?",s_id])
        unless c.empty? 
          #Check for initial products' token
          if c.first.product_id == -1
            #Initial products should be used
            my_search = initial_products
          else
            #Previous selected products have been found
            my_search = s_id
            break
          end
        end
      end
    end
    #Initial products is the default
    my_search = initial_products(id) unless my_search
    fqarray << "search_id = #{my_search}"
    #case @prefiltered_products
    #when 0 #Current products
    #  fqarray << "id in (select product_id from search_products where search_id = #{id})"
    #when -1 #Initial products
    #  fqarray << "id in (select product_id from search_products where search_id = #{initial_products})"
    #else #Old products = old search id
    #  fqarray << "id in (select product_id from search_products where search_id = #{@prefiltered_products})"
    #end
    userdataconts.each do |d|
      fqarray << "product_id in (select product_id from cont_specs where value <= #{d.max+0.00001} and value >= #{d.min-0.00001} and name = '#{d.name}')"
    end
    userdatacats.group_by(&:name).each do |name, ds|
      fqarray << "product_id in (select product_id from cat_specs where value in ('#{ds.map(&:value).join("','")}') and name = '#{name}')"
    end
    userdatabins.each do |d|
      fqarray << "product_id in (select product_id from bin_specs where value = #{d.value} and name = '#{d.name}')"
    end
    #Check for keyword search
    fqarray << "product_id in (select product_id from keyword_searches where searchterm = '#{keyword_search}')" if keyword_search
    fqarray.join(" AND ")
  end

  def self.createGroupBy(feat)
    s = Session.current
    myproducts = s.search.products
    product_ids = myproducts.map(&:product_id)
    if s.categorical.values.flatten.index(feat) # It's in the categorical array
      specs = product_ids.zip CatSpec.cachemany(product_ids,feat)
      grouping = specs.group_by{|spec|spec.value}.values.sort{|a,b| b.length <=> a.length}
      #grouping = Hash[grouping.each_pair{|k,v| grouping[k] = v.map(&:product_id)}.sort{|a,b| b.second.length <=> a.second.length}]
    elsif s.continuous.values.flatten.index(feat)
      specs = product_ids.zip ContSpec.cachemany(product_ids, feat).sort{|a,b|b[1] <=> a[1]}
      # [[id, low], [id, higher], ... [id, highest]]
      quartile_length = (specs.length / 4.0).ceil
      quartiles = []
      3.times do
        quartiles << specs.slice!(0,[quartile_length,specs.length].min)
      end
      quartiles << specs #The last quartile contains any extra products
      
      #Break boundry cases in quartiles where the same item is in two quartiles according to the following pattern
      # 1 ↓
      # 2
      # 3 ↑
      # 4 ↑

      #Move ties from Q1 to Q2
      unless quartiles[0].blank? || quartiles[1].blank?
        threshold_value = quartiles[1].first[1]
        splitpoint = quartiles[0].index(quartiles[0].find {|spec| spec[1] == threshold_value})
        quartiles[1] = quartiles[0].slice!(splitpoint..-1) + quartiles[1] unless splitpoint.nil?
      end
      
      #Move ties from Q4 to Q3
      unless quartiles[2].blank? || quartiles[3].blank?
        threshold_value = quartiles[2].last[1]
        splitpoint = quartiles[3].index(quartiles[3].reverse.find {|spec| spec[1] == threshold_value})
        quartiles[2] = quartiles[2] + quartiles[3].slice!(0..splitpoint) unless splitpoint.nil?
      end
      
      #Move ties from Q3 to Q2
      unless quartiles[1].blank? || quartiles[2].blank?
        threshold_value = quartiles[1].last[1]
        splitpoint = quartiles[2].index(quartiles[2].reverse.find {|spec| spec[1] == threshold_value})
        quartiles[1] = quartiles[1] + quartiles[2].slice!(0..splitpoint) unless splitpoint.nil?
      end
      
      grouping = quartiles.reject(&:blank?) # For cases like 9 items, where the quartile length ends up being 3.

    else # Binary feature. Do nothing for now.
    end
    grouping.map do |q|
      product_ids = q.map(&:product_id)
      prices_list = ContSpec.cachemanys(product_ids,"price")
      utility_list = ContSpec.cachemany(product_ids, "utility")
      {
        :min => q.first.value.to_s,
        :max => q.last.value.to_s,
        :size => q.count,
        :cheapest =>  Product.cached(product_ids[prices_list.index(prices_list.max)]),
        :best => Product.cached(product_ids[utility_list.index(utility_list.max)])
      }
    end
  end

  def self.keyword(keyword)
    #Check if this search has been done before
    #This could be cached in memcache, for performance
    previous_search = KeywordSearch.where(["keyword = ?", keyword]).limit(1).first
    if previous_search
      return !previous_search.product_id.nil?
    else
      product_ids = Product.search_for_ids(:per_page => 10000, :star => true, :conditions => {:product_type => Session.current.product_type, :title => keyword})
      if product_ids.empty?
        #Save a nil entry for failed searches
        KeywordSearch.create({:keyword => keyword})
        return false
      else
        new_entries = product_ids.map{|product_id| KeywordSearch.new({:keyword => keyword, :product_id => product_id})}
        KeywordSearch.transaction do
          new_entries.each(&:save)
        end
        return true
      end
    end
  end
  
  def initialize(p={})
    super({})
    #Set session id
    s = Session.current
    self.session_id = s.id
    old_search = s.lastsearch unless p["action_type"] == "initial" #Exception for initial clusters
    case p["action_type"]
    when "initial"
      #Initial load of the homepage
      #Prefiltered_products has three options:
      # Initial products: -1
      # Current products: 0
      # Previous products: id of previous search
      @prefiltered_products = -1 #initial products
      @myproducts = -1
    when "similar"
      #Browse similar button
      @prefiltered_products = 0 # current products
      @myproducts = Cluster.findbychild(p["cluster_hash"],p["child_id"])
      duplicateFeatures(old_search)
    when "nextpage"
      #the next page button has been clicked
      @prefiltered_products = old_search.id
      duplicateFeatures(old_search)
    when "filter"
      #product filtering has been done through keyword search of attribute filters
      createFeatures(p,old_search)
      #Find clusters that match filtering query
      if old_search && !expandedFiltering?(old_search)
        #Search is narrowed, so use old products to begin with
        @prefiltered_products = old_search.id
      else
        #Search is expanded, so use all products to begin with
        @prefiltered_products = -1 #Initial products
        @myproducts = -1
      end
    else
      #Error
    end
  end
  
  after_save do
    #Save user filters as well
    (userdataconts+userdatabins+userdatacats).each do |d|
      d.search_id = id
      d.save
    end
    #Record new prefiltered products
    if @myproducts && @myproducts.kind_of?(Array)
      SearchProduct.transaction do
        @myproducts.map{|product_id| SearchProduct.new({:product_id => product_id, :search_id => id})}.each(&:save)
      end
    end
  end
  
  # Duplicate the features of search (s) and the last search (os)
  def duplicateFeatures(os)
    @userdataconts = []
    @userdatabins = []
    @userdatacats = []
    if os
      os.userdataconts.each do |d|
        @userdataconts << d.class.new(d.attributes)
      end
      os.userdatacats.each do |d|
        @userdatacats << d.class.new(d.attributes)
      end
      os.userdatabins.each do |d|
        @userdatabins << d.class.new(d.attributes)
      end
    end
  end
  
  def createFeatures(p,old_search)
    s = Session.current
    #seperate myfilter into various parts
    @userdataconts = []
    @userdatabins = []
    @userdatacats = []
    
    p.each_pair do |k,v|
      next if v.blank? #Skip blank values, this should be fixed in JS
      if k.index(/(.+)_min/)
        #Continuous Features
        fname = Regexp.last_match[1]
        max = fname+'_max'
        @userdataconts << Userdatacont.new({:name => fname, :min => v, :max => p[max]})
      elsif s.binary["filter"].index(k)
        #Binary Features
        #Handle false booleans
        dobj = old_search.userdatabins.select{|d|d.name == k}.first
        if v != '0' || (!dobj.nil? && dobj.value == true)
          @userdatabins << Userdatabin.new({:name => k, :value => v})
        end
      elsif s.categorical["filter"].index(k)
        #Categorical Features
        v.split("*").each do |cat|
          @userdatacats << Userdatacat.new({:name => k, :value => cat})
        end
      elsif k == "keywordsearch"
        #Keyword Search
        self.keyword_search = v
      end
    end
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if false #cluster_count < Session.current.numGroups && cluster_count > 0
      if clusters.map{|c| c.size}.sum >= 9
        myclusters = splitClusters(clusters)
      else
        #Display only the deep children
        myclusters = clusters.map{|c| c.deepChildren}.flatten
      end
    else
      myclusters = clusters
    end
    updateClusters(myclusters)
  end
  
  # The intent of this function is to see if filtering is being done on a previously filtered set of clusters.
  # The reason for its existence is that filtering across, say, 50% of the total clusters is faster
  # than starting from the beginning every time.
  # Returns 'true' if the filtering is "expanded", ie., if the new filtering needs to examine clusters that weren't in the previous search.
  def expandedFiltering?(old_search)
    #Continuous feature
    olduserdataconts = old_search.userdataconts
    @userdataconts.each do |f|
      old = olduserdataconts.select{|c|c.name == f.name}.first
      if old # If the oldsession max value is not nil then calculate newrange
        oldrange = old.max - old.min
        newrange = f.max - f.min
        if newrange > oldrange
          return true #Continuous
        end
      end
    end
    #Binary Feature
    @userdatabins.each do |f|
      if f.value == false
        #Only works for one item submitted at a time
        @userdatabins.delete(f)
        return true #Binary
      end
    end
    #Categorical Feature
    olduserdatacats = old_search.userdatacats
    if @userdatacats.empty?
      return true unless olduserdatacats.empty?
    else
      @userdatacats.each do |f|
        old = olduserdatacats.select{|c|c.name == f.name}
        unless old.empty?
          newf = @userdatacats.select{|c|c.name == f.name}
          return true if newf.length == 0 && old.length > 0
          return true if old.length > 0 && newf.length > old.length
        end
      end
    end
    if self.keyword_search.blank?
      return true unless old_search.keyword_search.blank?
    end
    false
  end
  
  private
  
  def updateClusters(myclusters)
    return if myclusters.nil?
    mycluster = :c0=
    stringpresent = false #Don't set clusters if any of them are ids
    myclusters.each do |p|
      send(mycluster, case p.class.name
        when "String" then (stringpresent = true) && p
        when "Fixnum" then (stringpresent = true) && p.to_s
        when "Cluster" then p.id.to_s
      end )
      mycluster = mycluster.next # automatically advances from :c0= to :c1= etc.
    end
    self.cluster_count = myclusters.length
    self.clusters = myclusters unless stringpresent
  end
  
  def splitClusters(myclusters)
    while myclusters.length != Session.current.numGroups
      myclusters.sort! {|a,b| b.size <=> a.size}
      myclusters = split(myclusters.shift.children) + myclusters
    end
    myclusters.sort! {|a,b| b.size <=> a.size}
  end  
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size <=> a.size}
    [children.shift, MergedCluster.new(children)]
  end
  
  def normalize(a)
    total = a.max
    if total==0 
      a  
    else    
      a.map{|i| i.to_f/total}
    end  
  end
  
  def round2Decim(a)
    a.map{|n| (n*1000).round.to_f/1000}
  end
  
end
