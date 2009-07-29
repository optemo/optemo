require 'merged_cluster'
class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  #Array of normalized product counts
  def distribution(featureName)
    f = DbFeature.find_by_name_and_product_type_and_region(featureName,session.product_type,$region)
    stepsize = (f.max-f.min).to_f/10 
    res = []
    10.times do |i|
      min = f.min + stepsize*i
      max = min + stepsize
      clusters = []
      cluster_count.times do |c|
        clusters << "cluster_id = #{send(('c'+c.to_s).intern)}"
      end
      chooseclusters = clusters.join(' OR ')
      #Keyword search parameters
      options = session.searchpids.blank? ? '' : ' and ('+session.searchpids+')'
      #Filtering parameters
      options += session.filter && !Cluster.filterquery(session).blank? ? ' and '+Cluster.filterquery(session) : ''
      if max==min
        res << $nodemodel.find(:all, :conditions => ["#{featureName} = ? and (#{chooseclusters}) #{options}",max]).length
      else  
        res << $nodemodel.find(:all, :conditions => ["#{featureName} < ? and #{featureName} >= ? and (#{chooseclusters}) #{options}",max,min]).length
      end
    end
    round2Decim(normalize(res))
  end
  
#def distributions
#    dists = {}
#     
#    dbfeat = DbFeature.find_all_by_product_type_and_feature_type(session.product_type, 'Continuous')
#    acceptedNodes = clusters.map{|c| c.nodes(session)}.flatten ###??? more efficent way?
#    dbfeat.each do |f|
#      # intializing 
#      #dists{f.name} = Array.new(10,0) 
#      stepsize = (f.max-f.min).to_f/10 
#      acceptedNodes.each do |n| 
#        10.times do |i| 
#            min = f.min + stepsize * i
#            max = min + stepsize
#            if (max == min)
#              dists[f.name][i] += 1 if n.send(f.name) == min
#
#            elsif (n.send(f.name)>=min && n.send(f.name) < max)
#              debugger
#              dists[f.name][i] += 1 
#            end
#        end
#      end      
#   end    
#end 

  
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
  
  def clusterDescription
    clusterDs = []
    cluster_count.times do |j| 
      clusterDs[j] = []
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
           if (cRanges[0] >= high)
             clusterDs[i] << $model::ContinuousFeaturesDescHigh[f.name]
           elsif (cRanges[1] <= low)
             clusterDs[i] << $model::ContinuousFeaturesDescLow[f.name]
           end
        }
      end 
    end 
    for j in 0..cluster_count-1
      ds[j] = clusterDs[j]
    end 
    res = ds.map{|d| #d.blank? ? 'All Purpose' : 
      d.join(', ')}         
    res
  end
  

  def searchDescription
    des = []
   @dbfeatCon = DbFeature.find_all_by_product_type_and_feature_type_and_region(session.product_type, 'Continuous',$region)
   @dbfeatCon.each do |f|
      low = f.low
      high = f.high
      searchR = ranges(f.name)
      if (searchR[1]<=low)
           des <<  $model::ContinuousFeaturesDescLow[f.name]
      elsif (searchR[0]>=high)
           des <<  $model::ContinuousFeaturesDescHigh[f.name]
      end
    end  
   
    res = des.join(', ')
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
          c = $clustermodel.find(cluster_id)
        end
        #Remove empty clusters
        if c.isEmpty(session)
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
    s.parent_id = s.clusters.map{|c| c.parent_id}.sort[0]
    s.layer = s.clusters.map{|c| c.layer}.sort[0]
    s.desc = s.searchDescription
    s
  end
  
  def self.createFromPath_and_commit(path, session_id)
    s = createFromPath(path, session_id)
    s.save
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
    total = a.sum
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
