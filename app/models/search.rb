class Search < ActiveRecord::Base
  include CachingMemcached
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  
  ## Computes distributions (arrays of normalized product counts) for all continuous features 
  def distribution(featureName)
       dist = Array.new(21,0)
       min = $dbfeat[featureName].min
       max = $dbfeat[featureName].max
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
    @acceptedNodes ||= clusters.map{|c| c.nodes(session, searchpids)}.flatten 
  end
  
  #Range of product offerings
  def ranges(featureName)
     @sRange ||= {}
     if @sRange[featureName].nil?
       min = clusters.map{|c|c.ranges(featureName,session,searchpids)[0]}.compact.sort[0]
       max = clusters.map{|c|c.ranges(featureName,session,searchpids)[1]}.compact.sort[-1] 
       @sRange[featureName] = [min, max]
     end
     @sRange[featureName]  
  end
  
  def indicator(featureName)
    indic = false
    values = clusters.map{|c| c.indicator(featureName, session, searchpids)}
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
        norm = $dbfeat[featureName].max - $dbfeat[featureName].min
        norm = 1 if norm == 0
        feats[f] = clusters.map{|c| c.representative(session,searchpids)[f].to_f/norm}
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
          dir = feats[f].min == feats[f][i] ? "Lower" : "Higher"
          dir = feats[f].min == feats[f][i] ? "Lower" : feats[f].max == feats[f][i] ? "Higher" : "Avg"
          d << [dir,f].join(" ")
        end
        #Add binary labels
        d.unshift "Waterproof" if clusters[i].waterproof && layer == 1
        d.unshift "SLR" if clusters[i].slr && layer == 1
        if d.empty?
          @descs << "Avg"
        else
          @descs << d.join(", ")
        end
        #@descs[-1] = @descs.last + " (#{n})"
      end
    end
    @descs
  end
    
  def clusterDescription(clusterNumber)
    return if clusters.empty?
    clusterDs = Array.new 
    des = []
    slr=0
      $model::BinaryFeatures.each do |f|
        if clusters[clusterNumber].indicator(f, session, searchpids)
          (f=='slr' && indicator("slr"))? slr = 1 : slr =0
          des<< f if $model::DescFeatures.include?(f) 
        end
      end
      
      $model::ContinuousFeatures.each do |f|
        if $model::DescFeatures.include?(f) && !(f == "opticalzoom" && slr == 1)
              cRanges = clusters[clusterNumber].ranges(f, session, searchpids)
              if (cRanges[1] < $dbfeat[f]["low"])
                 clusterDs << {'desc' => "low_"+f, 'stat' => 0}  
              elsif (cRanges[0] > $dbfeat[f]["high"])
                 clusterDs <<  {'desc' => "high_"+f, 'stat' => 2}  
              elsif ((cRanges[0] >= $dbfeat[f]["low"]) && (cRanges[1] <= $dbfeat[f]["high"])) 
                  clusterDs <<  {'desc' => "avg_"+f, 'stat' => 1}
              end 
        end   
      end     
      
    clusterDs.sort!{|a,b| b['stat'] <=> a['stat']}
    clusterDs = clusterDs[0..1] if clusterDs.size > 2
    clusterDs[0] = {'desc' => "average", 'stat' => 1} if clusterDs.blank?
    des << clusterDs.map{|d| d['desc']};
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
    clusters.map{|c| c.size(session, searchpids)}.sum
  end
  
  def clusters= (clusters)
    @clusters = clusters
  end
  
  def clusters(mysession = session)
    if @clusters.nil?
      @clusters = []
      cluster_count.times do |i|
        cluster_id = send(:"c#{i}")
        if cluster_id.index('+')
          cluster_id.gsub(/[^(\d|+)]/,'') #Clean URL input
          #Merged Cluster
          c = MergedCluster.fromIDs(cluster_id.split('+'),mysession,searchpids)
        else
          #Single, normal Cluster
          c = findCachedCluster(cluster_id)
        end
        #Remove empty clusters
        if c.nil? || c.isEmpty(mysession,searchpids)
          self.cluster_count -= 1
        else
          @clusters << c 
        end
      end
    end
    @clusters
  end
  
  #The clusters argument can either be an array of cluster ids or an array of cluster objects if they have already been initialized
  def self.createFromClusters(clusters, session, keywordsearch, keyword)
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
    ns['session_id'] = session.id
    ns['searchpids'] = keywordsearch
    ns['searchterm'] = keyword
    s = new(ns)
    s.session = session
    unless clusters.nil? || clusters.empty? || clusters.first.class == String || clusters.first.class == Fixnum
        s.clusters = clusters.sort{|a,b| (a.size(session,keywordsearch)>1 ? -1 : 1) <=> (b.size(session,keywordsearch)>1 ? -1 : 1)}
    end
    s.fillDisplay
    s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s
  end
  
  def self.createFromClustersAndCommit(clusters, session, keywordsearch, keyword)
    s = createFromClusters(clusters, session, keywordsearch, keyword)
    s.save
    s
  end
  
  def to_s
    clusters.map{|c|c.id}.join('-')
  end
  
  def fillDisplay
    clusters #instantiate clusters to update cluster_count
    if cluster_count < 9 && cluster_count > 0
      if clusters.map{|c| c.size(session,searchpids)}.sum >= 9
        myclusters = splitClusters(clusters)
      else
        #Display only the deep children
        myclusters = clusters.map{|c| c.deepChildren(session,searchpids)}.flatten
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
      myclusters.sort! {|a,b| b.size(session,searchpids) <=> a.size(session,searchpids)}
      myclusters = split(myclusters.shift.children(session,searchpids)) + myclusters
    end
    myclusters.sort! {|a,b| b.size(session,searchpids) <=> a.size(session,searchpids)}
  end  
  
  def split(children)
    return children if children.length == 1
    children.sort! {|a,b| b.size(session,searchpids) <=> a.size(session,searchpids)}
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

