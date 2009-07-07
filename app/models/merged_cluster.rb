class MergedCluster
  attr_reader :clusters
  
  def initialize(clusters)
    @clusters = clusters
  end
  
  
  def self.fromIDs(product_type,clusters)
    product_type = product_type
    clusterobj = []
    clusters.compact.each do |c|
      clusterobj << $clustermodel.find(c.to_i)
    end
    new(clusterobj)
  end
  
  def id
    @clusters.map{|c|c.id}.join('+')
  end
  
  def parent_id
    @clusters.map{|c| c.parent_id}.sort[0]
  end
  
  def layer
    @clusters.map{|c| c.layer}.sort[0]
  end    
  #The subclusters
  def children(session)
    @clusters
  end
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(session, dC = [])
    clusters.map{|c| c.deepChildren(session)}.flatten
  end
  
  def ranges(featureName, session)
    @range ||= {}
    if @range[featureName].nil?
      values = nodes(session).map{|n| n.send(featureName)}.sort
      nodes_min = values[0]
      nodes_max = values[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end
  
  def nodes(session)
    unless @nodes
      clustersquery = @clusters.map{|c| "cluster_id = #{c.id}"}.join(' or ')
      @nodes = $nodemodel.find(:all, :order => 'price ASC', :conditions => "(#{clustersquery}) #{session.filter && !Cluster.filterquery(session).blank? ?
       ' and '+Cluster.filterquery(session) : ''}#{session.searchpids.blank? ? '' : ' and ('+session.searchpids+')'}")
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative(session)
    node = nodes(session).first
    $model.find(node.product_id) if node
  end 
  
  def size(session)
    unless @size
      if session.filter || !session.searchpids.blank?
        @size = nodes(session).length
      else
        @size = @clusters.map{|c|c.cluster_size}.sum
      end
    end
    @size
  end
  
  #Description for each cluster
  def description(session)
    des = []
    DbFeature.find_all_by_product_type_and_feature_type(session.product_type, 'Continuous').each do |f|
        low = f.low
        high = f.high  
        clusterR = ranges(f.name, session)
        return 'Empty' if clusterR[0].nil? || clusterR[1].nil?
        if (clusterR[1]<=low)
          des <<  $model::ContinuousFeaturesDescLow[f.name]
        elsif (clusterR[0]>=high)
          des <<  $model::ContinuousFeaturesDescHigh[f.name]
        end
      end 
      res = des.join(', ')
      res.blank? ? 'All Purpose' : res
  end
  
  def isEmpty(session)
    nodes(session).empty?
  end
  
  def clearCache
    @clusters.each{|c|c.clearCache}
  end
end