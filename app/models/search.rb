class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :userdatasearches, :clusters
  
  def userdataconts
      @userdataconts ||= Userdatacont.find_all_by_search_id(id)
  end
  
  def userdatacats
      @userdatacats ||= Userdatacat.find_all_by_search_id(id)
  end
  
  def userdatabins
      @userdatabins ||= Userdatabin.find_all_by_search_id(id)
  end

  def userdatasearches
    @userdatasearches ||= Userdatasearch.find_all_by_search_id(id)
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
       specs = ContSpec.cachemany(acceptedProductIDs, feat)
       specs.each do |s|
         current_dataset_minimum = s if s < current_dataset_minimum
         current_dataset_maximum = s if s > current_dataset_maximum
         i = ((s - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       [[current_dataset_minimum, current_dataset_maximum], round2Decim(normalize(dist))]
  end
  
  def acceptedProductIDs
    @acceptedProductIDs ||= (Session.current.directLayout ? products.map(&:id) : clusters.map{|c| c.nodes}.flatten.map(&:product_id))
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
    
  def result_count
    @result_count ||= (Session.current.directLayout ? products.length : clusters.map{|c| c.size}.sum)
  end
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def clusters(s = nil)
    if @clusters.nil?
      @clusters = []
      Session.current.numGroups.times do |i|
        cluster_id = send(:"c#{i}")
        next if cluster_id.nil?
        if cluster_id.index('+')
          cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
          #Merged Cluster
          c = MergedCluster.fromIDs(cluster_id.split('+'))
        else
          #Single, normal Cluster
          c = Cluster.cached(cluster_id)
        end
        #Remove empty clusters
        if c.nil? || c.isEmpty(s)
          self.cluster_count -= 1
        else
          @clusters << c 
        end
      end
    end
    @clusters
  end
  
  def products
    selected_features = (userdataconts.map{|c| c.name+c.min.to_s+c.max.to_s}+userdatabins.map{|c| c.name+c.value.to_s}+userdatacats.map{|c| c.name+c.value}+userdatasearches.map{|c| c.keyword}).hash
    CachingMemcached.cache_lookup("#{Session.current.product_type}Products#{selected_features}") do
      #Temporary fix for backward compatibility
      fq = Cluster.filterquery(self)
      fq = fq.gsub(/product_id in/i, "id in") if fq
      product_list = Product.valid.instock.where("#{fq unless fq.blank?}").all # product_type is taken care of by Product.valid
      product_list_ids = product_list.map(&:id)
      utility_list = ContSpec.cachemany_with_ids(product_list_ids, "utility")
      # Cannot avoid sorting, since this result is cached.
      # If there is an error here, you might need to run rake calculate_factors. (utility_list.length should match product_list.length)
      product_list.sort{|a, b| utility_list[b.id] <=> utility_list[a.id]}
    end
  end

  def self.createGroupBy(feat)
    s = Session.current
    myproducts = s.search.products
    if s.categorical.values.flatten.index(feat) # It's in the categorical array
      specs = CatSpec.cachemany_with_ids(myproducts.map(&:id),feat)
      grouping = specs.group_by{|spec|spec.value}
      grouping = Hash[grouping.each_pair{|k,v| grouping[k] = v.map(&:product_id)}.sort{|a,b| b.second.length <=> a.second.length}]
    elsif s.continuous.values.flatten.index(feat)
      specs = ContSpec.cachemany_with_ids(myproducts.map(&:id), feat).sort{|a,b| a[1] <=> b[1]}
      # [[id, low], [id, higher], ... [id, highest]]
      all_product_ids = specs.map{|s| s.first}
      quartile_length = (specs.length / 4.0).ceil
      grouping = {}
      if specs.length >= 4
        labels = ["Low", "Mid-low", "Mid-high", "High"]
      elsif specs.length == 3 
        labels = ["Low", "Medium", "High"]
      elsif specs.length == 2 
        labels = ["Low", "High"]
      else 
        labels = ["Medium"]
      end
      labels.each do |label|
        # This convoluted next line sets the names of the quartiles, using the specs' values at the beginning and end of each quartile.
        grouping[specs[0][1].to_i.to_s + " - " + specs[((quartile_length >= specs.length) ? (specs.length-1) : quartile_length)][1].to_f.ceil.to_s] = all_product_ids.slice!(0,quartile_length)
        specs.slice!(0, quartile_length)
      end
    else # Binary feature. Do nothing for now.
    end
    grouping.each_pair do |feat,product_ids| 
      prices = ContSpec.cachemany(product_ids,"price")
      cheapest = prices.zip(product_ids).sort{|a,b|a.first <=> b.first}.first.second
      product_ids.delete(cheapest)

      if product_ids.empty? # This means there was only one in the group, and "product_ids.delete(cheapest)" took it out.
        grouping[feat] = [Product.cached(cheapest)]
      else
        product_utility_hash = ContSpec.cachemany_with_ids(product_ids, "utility")
        best = product_utility_hash.sort{|a,b| b.second <=> a.second}.first.first
        product_ids.delete(best)
        grouping[feat] = [Product.cached(cheapest),Product.cached(best)] + product_ids # Just the first two products are searched for; the rest are left as just product_ids.
      end
    end
  end

  
  def initialize(myfilter=nil)
    #If clusters is nil use, previous clusters, if clusters is missing use initial clusters
    super()
    s = Session.current
    self.session_id = s.id
    if myfilter 
      if myfilter.has_key?("clusters")
        myclusters = myfilter.delete("clusters")
      else
        initialclusters = true
      end
    end
    # Deal with the page term first. This can come from a call to either #filter or #compare.
    unless myfilter.nil?
      self.page = myfilter.delete("page") # This will sometimes be nil, but that's fine.
    end
    old_search = s.lastsearch unless initialclusters #Exception for initial clusters
    if initialclusters
      #Load initial clusters
      updateClusters(Cluster.byparent(0))
    elsif myclusters
      unless myclusters.first.class == String || myclusters.first.class == Fixnum
        myclusters = myclusters.sort{|a,b| (a.size>1 ? -1 : 1) <=> (b.size>1 ? -1 : 1)}
      end
      # For a 'browse simliar' or a page change, we need to copy the old features over.
      duplicateFeatures(self, old_search)
      updateClusters(myclusters)
    elsif myfilter.nil? || myfilter.empty? # If myfilter only contained the "page" key, it's now empty, not nil
      # It was a group by page
      updateClusters(old_search ? old_search.clusters : [])
      duplicateFeatures(self, old_search)
    else #there is a filter/search term
      #seperate myfilter into various parts
      self.userdataconts = []
      self.userdatabins = []
      self.userdatacats = []
      self.userdatasearches = []
      
      myfilter.each_pair do |k,v|
        next if v.blank? #Skip blank values
        if k.index(/(.+)_min/)
          #Continuous Features
          fname = Regexp.last_match[1]
          max = fname+'_max'
          self.userdataconts << Userdatacont.new({:name => fname, :min => v, :max => myfilter[max]})
        elsif s.binary["filter"].index(k)
          #Binary Features
          #Handle false booleans
          dobj = old_search.userdatabins.select{|d|d.name == k}.first
          if v != '0' || (!dobj.nil? && dobj.value == true)
            self.userdatabins << Userdatabin.new({:name => k, :value => v})
          end
        elsif s.categorical["filter"].index(k)
          #Categorical Features
          v.split("*").each do |cat|
            self.userdatacats << Userdatacat.new({:name => k, :value => cat})
          end
        elsif k == "keywordsearch"
          #Keyword Search
          product_ids = Product.search_for_ids(:per_page => 10000, :star => true, :conditions => {:product_type => s.product_type, :title => v.downcase})
          unless product_ids.empty?
            self.userdatasearches << Userdatasearch.new({:keyword => v, :keywordpids => "product_id IN (" + product_ids.join(',') + ")"})
          else
            #No products found
            clusters = []
            return
          end
        end
      end
      #Find clusters that match filtering query
      if old_search && !expandedFiltering?(old_search)
        #Search is narrowed, so use current products to begin with
        # Why is this passing in (s)?
        updateClusters(old_search.clusters(self))
      else
        #Search is expanded, so use all products to begin with
        updateClusters(s.directLayout ? [] : Cluster.byparent(0).select{|c| not c.isEmpty(self)})
        #clusters = clusters.map{|c| c unless c.isEmpty}.compact
      end
    end
  end

  after_save do
    #Save user filters as well
    (userdataconts+userdatabins+userdatacats+userdatasearches).each do |d|
      d.search_id = id
      d.save
    end
  end
  
  # Duplicate the features of search (s) and the last search (os)
  def duplicateFeatures(current_search, os)
    current_search.userdataconts = []
    current_search.userdatabins = []
    current_search.userdatacats = []
    current_search.userdatasearches = []
    if os
      os.userdataconts.each do |d|
        current_search.userdataconts << d.class.new(d.attributes)
      end
      os.userdatacats.each do |d|
        current_search.userdatacats << d.class.new(d.attributes)
      end
      os.userdatabins.each do |d|
        current_search.userdatabins << d.class.new(d.attributes)
      end
      os.userdatasearches.each do |d|
        current_search.userdatasearches << d.class.new(d.attributes)
      end
    end
  end
  
  def to_s
    clusters.map{|c|c.id}.join('-')
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
    userdataconts.each do |f|
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
    userdatabins.each do |f|
      if f.value == false
        #Only works for one item submitted at a time
        userdatabins.delete(f)
        return true #Binary
      end
    end
    #Categorical Feature
    olduserdatacats = old_search.userdatacats
    if userdatacats.empty?
      return true unless olduserdatacats.empty?
    else
      userdatacats.each do |f|
        old = olduserdatacats.select{|c|c.name == f.name}
        unless old.empty?
          newf = userdatacats.select{|c|c.name == f.name}
          return true if newf.length == 0 && old.length > 0
          return true if old.length > 0 && newf.length > old.length
        end
      end
    end
    if userdatasearches.empty?
      return true unless old_search.userdatasearches.empty?
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
