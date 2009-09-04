require 'merged_cluster'
class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  ## Computes distributions (arrays of normalized product counts) for all continuous features 
  def distribution(featureName)
      @acceptedNodes ||= clusters.map{|c| c.nodes(session)}.flatten
      dist = Array.new(21,0)
      dbfeat = DbFeature.find_by_region_and_product_type_and_name($region, session.product_type, featureName)
      min = dbfeat.min
      max = dbfeat.max
      #min = session.features.send("#{featureName}_min".intern) || ranges(featureName)[0]
      #max = session.features.send("#{featureName}_max".intern) || ranges(featureName)[1]
      stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
      itof = $model::ItoF.include?(featureName)
      @acceptedNodes.each do |n| 
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
  
  def countBinary
    counts = {}
     dbfeat=DbFeature.find_all_by_region_and_product_type_and_feature_type($region, session.product_type, 'Binary')
     @acceptedNodes ||= clusters.map{|c| c.nodes(session)}.flatten 
     dbfeat.each do |f|
       counts[f.name] = @acceptedNodes.map{|n| n.send(f.name)? 1 : 0}.sum
     end   
     counts
  end
  
  #Range of product offerings
  def ranges(featureName)
     @sRange ||= {}
     if @sRange[featureName].nil?
       min = clusters.map{|c|c.ranges(featureName,session)[0]}.compact.sort[0]
       max = clusters.map{|c|c.ranges(featureName,session)[1]}.compact.sort[-1] 
       @sRange[featureName] = [min, max]
     end
     @sRange[featureName]  
  end
  
  def indicator(featureName)
    indic = false
    values = clusters.map{|c| c.indicator(featureName, session)}
    if values.index(false).nil?
      indic = true
    end  
    indic
  end
  
  def relativeDescriptions
    return if clusters.empty?
    @descs ||= []
    if @descs.empty?
      feats = {}
      $model::ContinuousFeaturesF.each do |f|
        dbfeat = DbFeature.find_by_region_and_product_type_and_name($region, session.product_type, f)
        norm = dbfeat.max - dbfeat.min
        norm = 1 if norm == 0
        feats[f] = clusters.map{|c| c.representative(session)[f].to_f/norm}
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
          #elsif feats[f].sort[4] == feats[f][i]
          #  dist[f] = [feats[f].sort[4]-feats[f].sort[3],feats[f].sort[5]-feats[f].sort[4]].min
          #  dist.delete(f) if dist[f] == 0 #Remove ties
          end
        end if cluster_count > 1
        n = dist.count
        d = []
        dist.sort{|a,b| a[1] <=> b[1]}.each do |f,v|
          dir = feats[f].min == feats[f][i] ? "Lower" : "Higher"
          #dir = feats[f].min == feats[f][i] ? "Lower" : feats[f].max == feats[f][i] ? "Higher" : "Avg"
          d << [dir,$model::FeaturesDisp[f]].join(" ")
        end
        #Add binary labels
        d.unshift "Waterproof" if clusters[i].waterproof && layer == 1
        d.unshift "SLR" if clusters[i].slr && layer == 1
        if d.empty?
          @descs << "Average"
        else
          @descs << d.join(", ")
        end
        #@descs[-1] = @descs.last + " (#{n})"
      end
    end
    @descs
  end
  
  def clusterDescription
    return if clusters.empty?
    clusterDs = []
    statDs = []
    desCount = Array.new(clusters.size)
    cluster_count.times do |j| 
      clusterDs[j] = []
      statDs[j] = []
      desCount[j] = 0
   end  
    ds = []
    cRanges = []
    @dbfeatCon.each do |f|
      low = f.low
      high = f.high
      searchR = ranges(f.name)
      unless (searchR[0] >= high || searchR[1]<=low) 
        clusters.each_index {|i| 
          cRanges = clusters[i].ranges(f.name, session)
           if (cRanges[1] <= low)
             clusterDs[i] << $model::ContinuousFeaturesDescLow[f.name]  
           elsif (cRanges[0] >= high)
             clusterDs[i] <<  $model::ContinuousFeaturesDescHigh[f.name]        
           end
        }
      end 
    end 
    for j in 0..cluster_count-1
      ds[j] = clusterDs[j]
    end 
    res = ds.map{|d| #d.blank? ? 'All Purpose' : 
      d.compact.join(', ')}         
    res
  end
  
  
  def searchDescription
    return if clusters.empty?
    des = []
    desCount = 0
    statDs = [] 
   @dbfeatCon = DbFeature.find_all_by_product_type_and_feature_type_and_region(session.product_type, 'Continuous',$region)
 
   @dbfeatCon.each do |f|
      low = f.low
      high = f.high 
      searchR = ranges(f.name)
      if (searchR[1] <= low)
           des << $model::ContinuousFeaturesDescLow[f.name]
      elsif (searchR[0]>=high)
           des << $model::ContinuousFeaturesDescHigh[f.name]   
      end
    end  
    res = des.compact.join(', ')
    res.blank? ? 'All Purpose' : res 
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
    clusters.map{|c| c.size(session)}.sum
  end
  
  def clusters
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        cluster_id = send(:"c#{i}")
        if cluster_id.index('+')
          cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
          #Merged Cluster
          c = MergedCluster.fromIDs(session.product_type,cluster_id.split('+'),session)
        else
          #Single, normal Cluster
          c = $clustermodel.find_by_id(cluster_id)
        end
        #Remove empty clusters
        if c.nil? || c.isEmpty(session)
          self.cluster_count -= 1
        else
          @clusters << c 
        end
        @clusters.sort!{|a,b|b.utility(session) <=> a.utility(session)}
      end
    end
    @clusters
  end
  
  def self.createFromPath(path, session_id)
    ns = {}
    mycluster = "c0"
    ns['cluster_count'] = path.length
    path.each do |p|
      ns[mycluster] = p
      mycluster.next!
    end
    ns['session_id'] = session_id
    s = new(ns)
    
    s.fillDisplay
    return nil if s.clusters.empty?
    s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s.desc = s.searchDescription
    s
  end
  
  def self.createFromPath_and_commit(path, session_id)
    s = createFromPath(path, session_id)
    s.save unless s.nil?
    s
  end
  
  def to_s
    clusters.map{|c|c.id}.join('-')
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if cluster_count < 9 && cluster_count > 0
      if clusters.map{|c| c.size(session)}.sum >= 9
        myclusters = splitClusters(clusters)
      else
        #Display only the deep children
        myclusters = clusters.map{|c| c.deepChildren(session)}.flatten
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
    while myclusters.length != 9
      myclusters.sort! {|a,b| b.size(session) <=> a.size(session)}
      myclusters = split(myclusters.shift.children(session)) + myclusters
    end
    myclusters.sort! {|a,b| b.size(session) <=> a.size(session)}
  end  
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size(session) <=> a.size(session)}
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
