class Search < ActiveRecord::Base
  attr_writer :userdataconts, :userdatacats, :userdatabins, :userdatasearches
  
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
       return [] if max.nil? || min.nil?
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       specs = ContSpec.cachemany(acceptedProductIDs, feat)
       specs.each do |s|
         i = ((s - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       round2Decim(normalize(dist))
  end
  
  def acceptedProductIDs
    @acceptedProductIDs ||= ($SimpleLayout ? products.map(&:id) : clusters.map{|c| c.nodes}.flatten.map(&:product_id))
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
    return if clusters.empty?
    @reldescs ||= []
    if @reldescs.empty?
      feats = {}
      $Continuous["filter"].each do |f|
        norm = ContSpec.allMinMax(f)[1] - ContSpec.allMinMax(f)[0]
        norm = 1 if norm == 0
        feats[f] = clusters.map{ |c| c.representative}.compact.map {|c| c[f].to_f/norm } 
      end
      cluster_count.times do |i|
        dist = {}
        $Continuous["filter"].each do |f|
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
      $Binary["filter"].each do |f|
        if clusters[clusterNumber].indicator(f)
          (f=='slr' && indicator("slr"))? slr = 1 : slr =0
          des<< f if $config["DescFeatures"].include?(f) 
        end
      end
      
      $Continuous["desc"].each do |f|
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
    $Continuous["desc"].each do |f|
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
    @result_count ||= ($SimpleLayout ? products.length : clusters.map{|c| c.size}.sum)
  end
  
  def clusters= (clusters)
    @clusters = clusters
  end
  
  def clusters(s = nil)
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        cluster_id = send(:"c#{i}")
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
  
  def products(sort_by_utility=true)
    selected_features = (userdataconts.map{|c| c.name+c.min.to_s+c.max.to_s}+userdatabins.map{|c| c.name+c.value.to_s}+userdatacats.map{|c| c.name+c.value}+userdatasearches.map{|c| c.keyword}).hash
    CachingMemcached.cache_lookup("#{$product_type}Products#{selected_features}") do
      #Temporary fix for backward compatibility
      fq = Cluster.filterquery(self)
      fq = fq.gsub(/product_id in/i, "id in") if fq
      product_list = Product.valid.instock.find(:all, :conditions => "product_type = '#{$product_type}'#{' and '+fq unless fq.blank?}")
      product_list_ids = product_list.map(&:id)
      if sort_by_utility
        utility_list = {}
        $Continuous["filter"].each do |feat|
          Factor.cachemany_with_ids(product_list_ids, feat).each do |factor|
            utility_list[factor.product_id] = utility_list[factor.product_id].to_f + factor.value # nil.to_f is 0.0, so this works.
          end
        end
        product_list.sort{|a, b| utility_list[a.id] <=> utility_list[b.id]}
      else # This must be explicit
        product_list
      end
    end
  end

  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  
  def self.createGroupBy(feat)
    myproducts = Session.current.search.products(false) # This disables utility sorting, since it's not needed, and is more efficient.
    specs = CatSpec.cachemany_with_ids(myproducts.map(&:id),feat)
    grouping = specs.group_by{|spec|spec.value}
    grouping = Hash[grouping.each_pair{|k,v| grouping[k] = v.map(&:product_id)}.sort{|a,b| b.second.length <=> a.second.length}]
    grouping.each_pair do |feat,products| 
      prices = ContSpec.cachemany(products,"price")
      cheapest = prices.zip(products).sort{|a,b|a.first <=> b.first}.first.second
      products.delete(cheapest)
      product_utility_hash = {}
      $Continuous["filter"].each do |spec|
        Factor.cachemany_with_ids(products, spec).each do |f|
          product_utility_hash[f.product_id] = product_utility_hash[f.product_id].to_f + f.value
        end
      end
      if products.empty?
        best = cheapest # This means there was only one in the group, and "products.delete(cheapest)" took it out.
      else
        best = product_utility_hash.sort{|a,b| b.second <=> a.second}.first.first
        products.delete(best)
      end
      # Just the first two products are searched for; the rest are left as just product_ids.
      grouping[feat] = [Product.cached(cheapest),Product.cached(best)]+products
    end
  end

  def self.createSearchAndCommit(os, clusters=nil, myfilter =nil, current_search_term=nil)
    # Deal with the page term first. This can come from a call to either #filter or #compare.
    current_session = Session.current
    s = new({:session_id => current_session.id})
    unless myfilter.nil?
      s.page = myfilter['page'] # This will sometimes be nil, but that's fine.
      myfilter.delete("page")
    end

    if clusters
      mycluster = "c0="
      clusters.each do |p|
        s.send(mycluster.intern, case p.class.name
          when "String" then p
          when "Fixnum" then p.to_s
          when "Cluster" then p.id.to_s
        end )
        mycluster.next! # automatically advances from 'c0=' to 'c1=' etc.
      end
      unless clusters.nil? || clusters.empty? || clusters.first.class == String || clusters.first.class == Fixnum
          s.clusters = clusters.sort{|a,b| (a.size>1 ? -1 : 1) <=> (b.size>1 ? -1 : 1)}
      end
      # For a 'browse simliar' or a page change, we need to copy the old features over.
      s.save
      self.duplicateFeatures(s, os)
    else # If no clusters, there should be a filter and / or search term, or a page term.
      if myfilter.nil? || myfilter.empty? # If myfilter only contained the "page" key, it's now empty, not nil
        # It was a new page.
        s.clusters = (os ? os.clusters : [])
        s.save
        self.duplicateFeatures(s, current_session.search)
      else
        #Delete blank values
        myfilter.delete_if{|k,v|v.blank?}

        unless current_search_term.blank?
          product_ids = Product.search_for_ids(:per_page => 10000, :star => true, :conditions => {:product_type => $product_type, :title => current_search_term.downcase})
          unless product_ids.empty?
            s.userdatasearches = [Userdatasearch.new({:keyword => current_search_term, :keywordpids => "product_id IN (" + product_ids.join(',') + ")"})]
          else
            s.userdatasearches = []
            s.clusters = []
            return s
          end
        end

        myfilter["session_id"] = current_session.id
        #Handle false booleans
        $Binary["filter"].each do |f|
          dobj = current_session.search.userdatabins.select{|d|d.name == f}.first
          myfilter.delete(f.intern) if myfilter[f.intern] == '0' && (dobj.nil? || dobj.value != true)
        end    

        #seperate myfilter into various parts
        s.userdataconts = []
        s.userdatabins = []
        s.userdatacats = []

        myfilter.each_pair do |k,v|
          if k.index(/(.+)_min/)
            fname = Regexp.last_match[1]
            max = fname+'_max'
            s.userdataconts << Userdatacont.new({:name => fname, :min => v, :max => myfilter[max]})
          elsif $Binary["filter"].index(k)
            s.userdatabins << Userdatabin.new({:name => k, :value => v})
          elsif $Categorical["filter"].index(k)
            v.split("*").each do |cat|
              s.userdatacats << Userdatacat.new({:name => k, :value => cat})
            end
          end
        end
        #Find clusters that match filtering query
        if !s.expandedFiltering? && os
          #Search is narrowed, so use current products to begin with
          # Why is this passing in (s)?
          s.clusters = os.clusters(s)
        else
          #Search is expanded, so use all products to begin with
          s.clusters = ($SimpleLayout ? [] : Cluster.byparent(0).delete_if{|c| c.isEmpty(s)}) #This is broken for test profile in Rails 2.3.5
          #clusters = clusters.map{|c| c unless c.isEmpty}.compact
        end
      end
    end
    s.cluster_count = s.clusters.length
    s.commitfilters
    s
  end
      
  # Duplicate the features of search (s) and the last search (os)
  def self.duplicateFeatures(s, os)
    if os
      (os.userdataconts+os.userdatacats+os.userdatabins+os.userdatasearches).each do |d|
        nd = d.class.new(d.attributes)
        nd.search_id = s.id
        nd.save
      end
    end
  end

  def self.createInitialClusters(myfilter) # myfilter could contain page number
    Session.current.search = self.createSearchAndCommit(nil, Cluster.byparent(0), myfilter) # nil search
  end
  
  def commitfilters
    mycluster = "c0="
    clusters.each do |p|
      send(mycluster.intern, p.id.to_s)
      mycluster.next!
    end
    save
    
    #Save user filters
    (userdataconts+userdatabins+userdatacats+userdatasearches).each do |d|
      d.search_id = id
      d.save
    end
  end
  
  def to_s
    clusters.map{|c|c.id}.join('-')
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if false #cluster_count < $NumGroups && cluster_count > 0
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
  def expandedFiltering?
    mysearch = Session.current.search
    #Continuous feature
    userdataconts.each do |f|
      old = Userdatacont.find_by_search_id_and_name(mysearch.id,f.name)
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
    if userdatacats.empty?
      return true if Userdatacat.find_by_search_id(mysearch.id)
    else
      userdatacats.each do |f|
        old = Userdatacat.find_all_by_search_id_and_name(mysearch.id,f.name)
        unless old.empty?
          newf = userdatacats.select{|c|c.name == f.name}
          return true if newf.length == 0 && old.length > 0
          return true if old.length > 0 && newf.length > old.length
        end
      end
    end
    if userdatasearches.empty?
      return true if Userdatasearch.find_all_by_search_id(mysearch.id)
    end
    false
  end
  
  private
  
  def updateClusters(myclusters)
    self.cluster_count = myclusters.length
    myc = "c0="
    cluster_count.times do |i|
      send(myc.intern,myclusters[i].id)
      myc.next!
    end
    @clusters = myclusters
  end
  
  def splitClusters(myclusters)
    while myclusters.length != $NumGroups
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
