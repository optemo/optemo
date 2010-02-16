class Search < ActiveRecord::Base
  include CachingMemcached
  belongs_to :session
  
  ## Computes distributions (arrays of normalized product counts) for all continuous features 
  def distribution(featureName)
       dist = Array.new(21,0)
       min = DbFeature.featurecache(featureName).min
       max = DbFeature.featurecache(featureName).max
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       itof = $model::ItoF.include?(featureName)
       acceptedNodes.each do |n|
         if (itof==true && min>=max-1) || (itof==false && min>=max-0.1)
           #No range so fill everything in
           dist = Array.new(dist.length,1)
         else
           i = ((n.send(featureName) - min) / stepsize).to_i
           dist[i] += 1 if i < dist.length
         end
       end  
       round2Decim(normalize(dist))
  end
  
  def countBinary(featureName)
     acceptedNodes.map{|n| n[featureName]? 1 : 0}.sum
  end
  
  def countBrands(brandName)
    
    acceptedNodes.map{|n| (n["brand"]== brandName)? 1 : 0}.sum
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
      $model::ContinuousFeaturesF.each do |f|
        norm = DbFeature.featurecache(f).max - DbFeature.featurecache(f).min
        norm = 1 if norm == 0
        feats[f] = clusters.map{|c| c.representative[f].to_f/norm}
      end
      cluster_count.times do |i|
        dist = {}
        $model::ContinuousFeaturesF.each do |f|
          if feats[f].min == feats[f][i]
            dist[f] = feats[f].sort[1] - feats[f][i]
            dist.delete(f) if dist[f] == 0 && feats[f].sort[2] == feats[f][i]#Remove ties
          elsif feats[f].max == feats[f][i]
            dist[f] = feats[f][i] - feats[f].sort[-2]
            dist.delete(f) if dist[f] == 0  && feats[f].sort[-3] == feats[f][i]#Remove ties
          elsif feats[f].sort[4] == feats[f][i]
            dist[f] = ([feats[f].sort[4]-feats[f].sort[3],feats[f].sort[5]-feats[f].sort[4]].min) - 1
            dist.delete(f) if dist[f] == -1 #Remove ties
          end
        end if cluster_count > 1
        n = dist.count
        d = []
        dist.sort{|a,b| b[1] <=> a[1]}[0..1].each do |f,v|
          dir = feats[f].min == feats[f][i] ? "lower" : "higher"
          dir = feats[f].min == feats[f][i] ? "lower" : feats[f].max == feats[f][i] ? "higher" : "avg"
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
    
  def clusterDescription(clusterNumber)
    return if clusters.empty?
    clusterDs = Array.new 
    des = []
    slr=0
      $model::BinaryFeatures.each do |f|
        if clusters[clusterNumber].indicator(f)
          (f=='slr' && indicator("slr"))? slr = 1 : slr =0
          des<< f if $model::DescFeatures.include?(f) 
        end
      end
      
      $model::ContinuousFeatures.each do |f|
        if $model::DescFeatures.include?(f) && !(f == "opticalzoom" && slr == 1)
              cRanges = clusters[clusterNumber].ranges(f)
              if (cRanges[1] < DbFeature.featurecache(f).low)
                 clusterDs << {'desc' => "low_"+f, 'stat' => 0}  
              elsif (cRanges[0] > DbFeature.featurecache(f).high)
                 clusterDs <<  {'desc' => "high_"+f, 'stat' => 2}  
              elsif ((cRanges[0] >= DbFeature.featurecache(f).low) && (cRanges[1] <= DbFeature.featurecache(f).high)) 
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
    $model::DescFeatures.each do |f|
      low = DbFeature.featurecache(f).low
      high = DbFeature.featurecache(f).high
      searchR = ranges(f)
      return ['Empty'] if searchR[0].nil? || searchR[1].nil?
      if (searchR[1]<=low)
           des <<  "low_#{f}"
      elsif (searchR[0]>=high)
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
  
  def clusters
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
          c = findCachedCluster(cluster_id)
        end
        #Remove empty clusters
        if c.nil? || c.isEmpty
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
        when $clustermodel.name then p.id.to_s
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
    s.fillDisplay
    s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s
  end
  
  def self.createFromClustersAndCommit(clusters)
    s = createFromClusters(clusters)
    s.save
    s
  end
  
  def self.createFromKeywordSearch(nodes)
    product_id_array = nodes.map{ |node| node.product_id }
    if !(product_id_array.nil?) && product_id_array.length < 50 # Guess; this should be profiled later.
      node_array = product_id_array.map { |id| Session.current.findCachedNode(id) } # This might not be ideal but it should work
      clusters = node_array.map { |node| Session.current.findCachedCluster(node.cluster_id) }.uniq

      while clusters.length > $NumGroups
        clusters = clusters.map do |cluster|
          if cluster.parent_id != 0 # It's possible to have clusters at different layers, so we need to check for this.
            cluster.findCachedCluster(cluster.parent_id)
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
  
  def to_s
    clusters.map{|c|c.id}.join('-')
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if cluster_count < $NumGroups && cluster_count > 0
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

