class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :products_size
  
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
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
  
  #Sets to use the initial products and checks whether they're in the database
  def initial_products
    products_id = Product.initial
    if SearchProduct.where(["search_id = ?", products_id]).limit(1).empty?
      SearchProduct.transaction do
        Product.valid.instock.map{|product| SearchProduct.new(:product_id => product.id, :search_id => products_id)}.each(&:save)
      end
    end
    products_id
  end
  
  def products_size
    @products_size ||= products.size
  end
  
  def products
    SearchProduct.fq2
  end
  
  def products_search_id
    if @myproducts
      #A cluster was chosen
      my_search = id
    else
      current_s = self
      while(my_search.nil?)
        if current_s.initial
          my_search = initial_products
        else
          c = SearchProduct.where(["search_id = ?",current_s.id])
          if c.empty?
            begin
              current_s = Search.find(current_s.parent_id)
            rescue (ActiveRecord::RecordNotFound)
              #There's an error let's just go back to the initial products
              debugger
              my_search = initial_products
            end
          else
            #Previous selected products have been found
            my_search = current_s.id
          end
        end
      end
    end
    my_search
  end

  def groupings
    return [] if groupby.nil? 
    s = Session.current
    if s.categorical["all"].index(groupby) 
      # It's in the categorical array
      specs = products.zip CatSpec.cachemany(products, groupby)
      grouping = specs.group_by{|spec|spec[1]}.values.sort{|a,b| b.length <=> a.length}
    elsif s.continuous["all"].index(groupby)
      #The chosen feature is continuous
      specs = products.zip ContSpec.by_feat(groupby).sort
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
      product_ids = q.map(&:first)
      prices_list = ContSpec.cachemany(product_ids,"price")
      utility_list = ContSpec.cachemany(product_ids, "utility")
      {
        :min => q.first.last.to_s,
        :max => q.last.last.to_s,
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
    unless p["action_type"] == "initial" #Exception for initial clusters
      old_search = Search.find_by_id_and_session_id(p["search_hist"],s.id) if p["search_hist"]
      old_search = s.lastsearch if old_search.nil?
      self.parent_id = old_search.id
    end
    case p["action_type"]
    when "initial"
      #Initial load of the homepage
      self.initial = true
      @userdataconts = []
      @userdatabins = []
      @userdatacats = []
    when "similar"
      #Browse similar button
      @myproducts = Cluster.cached(p["cluster_hash"]) # current products
      duplicateFeatures(old_search)
    when "nextpage"
      #the next page button has been clicked
      self.page = p[:page]
      duplicateFeatures(old_search)
    when "groupby"
      self.groupby = p[:feat]
      duplicateFeatures(old_search)
    when "filter"
      #product filtering has been done through keyword search of attribute filters
      createFeatures(p,old_search)
      #Find clusters that match filtering query
      if old_search && !expandedFiltering?(old_search)
        #Search is narrowed, so use old products to begin with
      else
        #Search is expanded, so use all products to begin with
        self.initial = true
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
    if @myproducts
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
      elsif k == "search"
        #Keyword Search
        self.keyword_search = v
      end
    end
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
end
