class Search < ActiveRecord::Base
  belongs_to :session
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
       min = CachingMemcached.minSpec(feat)
       max = CachingMemcached.maxSpec(feat)
       return [] if max.nil? || min.nil?
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       id_array = acceptedNodes.map(&:product_id)
       specs = ContSpec.cachemany(id_array, feat)
       specs.each do |s|
         i = ((s - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       round2Decim(normalize(dist))
  end
  
  def acceptedNodes
    @acceptedNodes ||= clusters.map{|c| c.nodes}.flatten 
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
        norm = CachingMemcached.maxSpec(f) - CachingMemcached.minSpec(f)
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
              if (cRanges[1] < CachingMemcached.lowSpec(f))
                 clusterDs << {'desc' => "low_"+f, 'stat' => 0}  
              elsif (cRanges[0] > CachingMemcached.highSpec(f))
                 clusterDs <<  {'desc' => "high_"+f, 'stat' => 2}  
              elsif ((cRanges[0] >= CachingMemcached.lowSpec(f)) && (cRanges[1] <= CachingMemcached.highSpec(f))) 
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
      if (searchR[1] <= CachingMemcached.lowSpec(f))
           des <<  "low_#{f}"
      elsif (searchR[0] >= CachingMemcached.highSpec(f))
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
    clusters.map{|c| c.size}.sum
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
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def self.createFromClusters(clusters)
    ns = {}
    mycluster = "c0"
    ns['cluster_count'] = clusters.length
    clusters.each do |p|
      ns[mycluster] = case p.class.name
        when "String" then p
        when "Fixnum" then p.to_s
        when "Cluster" then p.id.to_s
      end
      mycluster.next!
    end
    ns['session_id'] = Session.current.id
    ns['searchpids'] = Session.current.keywordpids
    ns['searchterm'] = Session.current.keyword
    s = new(ns)
    s.session = Session.current
    unless clusters.nil? || clusters.empty? || clusters.first.class == String || clusters.first.class == Fixnum
        s.clusters = clusters.sort{|a,b| (a.size>1 ? -1 : 1) <=> (b.size>1 ? -1 : 1)}
    end
#    s.fillDisplay
    #I think these are deprecated
    #s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    #s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s
  end
  
  def self.createFromFilters(myfilter)
    #Delete blank values
    myfilter.delete_if{|k,v|v.blank?}
    #Fix price, because it's stored as int in db
    myfilter[:session_id] = Session.current.id
    #Handle false booleans
    $Binary["filter"].each do |f|
      dobj = Session.current.search.userdatabins.select{|d|d.name == f}.first
      myfilter.delete(f.intern) if myfilter[f.intern] == '0' && (dobj.nil? || dobj.value != true)
    end
    
    s = new({:session_id => Session.current.id, :searchpids => Session.current.keywordpids, :searchterm => Session.current.keyword})
    
    #seperate myfilter into various parts
    s.userdataconts = []
    s.userdatabins = []
    s.userdatacats = []
    
    myfilter.each_pair {|k,v|
      if k.index(/(.+)_min/)
        fname = Regexp.last_match[1]
        max = fname+'_max'
        s.userdataconts << Userdatacont.new({:name => fname, :min => v, :max => myfilter[max]})
      elsif $Binary["filter"].index(k)
        s.userdatabins << Userdatabin.new({:name => k, :value => v})
      elsif $Categorical["filter"].index(k)
        s.userdatacats << Userdatacat.new({:name => k, :value => v})
      end
    }
    
    #Find clusters that match filtering query
    if !s.expandedFiltering? && Session.current.searches.last
      #Search is narrowed, so use current products to begin with
      s.clusters = Session.current.searches.last.clusters(s)
    else
      #Search is expanded, so use all products to begin with
      s.clusters = Cluster.byparent(0).delete_if{|c| c.isEmpty} #This is broken for test profile in Rails 2.3.5
      #clusters = clusters.map{|c| c unless c.isEmpty}.compact
    end
    s.cluster_count = s.clusters.length
    s
  end
  
  def self.createFromClustersAndCommit(clusters)
    s = createFromClusters(clusters)
    s.save
    #Duplicate the features
    os = Session.current.search
    if os
      (os.userdataconts+os.userdatacats+os.userdatabins).each do |d|
        nd = d.class.new(d.attributes)
        nd.search_id = s.id
        nd.save
      end
    end
    s
  end
  
  def self.createFromKeywordSearch(nodes)
    if !(nodes.nil?) && nodes.length < 50 # Guess; this should be profiled later.
      clusters = nodes.map { |node| Cluster.cached(node.cluster_id) }.uniq

      while clusters.length > $NumGroups
        clusters = clusters.map do |cluster|
          if cluster.parent_id != 0 # It's possible to have clusters at different layers, so we need to check for this.
            Cluster.cached(cluster.parent_id)
          else
            cluster
          end
        end
        clusters = clusters.uniq
      end
    else
      clusters = nodes.map{|n|n.cluster_id}.uniq
    end
    createFromClustersAndCommit(clusters)
  end
  
  def self.createInitialClusters
    #Remove search terms
    Session.current.keywordpids = nil
    Session.current.keyword = nil
    Session.current.search = self.createFromClustersAndCommit(Cluster.byparent(0))
  end
  
  def commitfilters
    mycluster = "c0="
    clusters.each do |p|
      send(mycluster.intern, p.id.to_s)
      mycluster.next!
    end
    save
    
    #Save user filters
    (userdataconts+userdatabins+userdatacats).each do |d|
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
  
  def expandedFiltering?
    #Continuous feature
    userdataconts.each do |f|
      old = Userdatacont.find_by_search_id_and_name(Session.current.search.id,f.name)
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
    userdatacats.each do |f|
      old = Userdatacat.find_by_search_id_and_name(Session.current.search.id,f.name)
      unless old.empty?
        newf = userdatacats.find_all_by_name(f.name)
        return true if newf.length == 0 && old.length > 0
        return true if old.length > 0 && newf.length > old.length
      end
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

