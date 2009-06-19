class MergedCluster
  attr_reader :product_type, :clusters
  def initialize(product_type,clusters)
    @product_type = product_type
    @clusters = []
    clusters.compact.each do |c|
      @clusters << (@product_type+'Cluster').constantize.find(c.to_i)
    end
  end
  
  #The subclusters
  def children(session)
    unless @children
      parentsonly = @clusters.map{|c| "parent_id = #{c.id}"}.join(' or ')
      @children = (@product_type+'Cluster').constantize.find(:all, :conditions => parentsonly)
      #Check that children are not empty
      if session.filter || !session.searchpids.blank?
        @children.delete_if{|c| c.isEmpty(session)}
      end
    end
    @children
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
  
  def nodes(session, filters=nil)
    unless @nodes
      clustersquery = @clusters.map{|c| "cluster_id = #{c.id}"}.join(' or ')
      @nodes = (session.product_type + 'Node').constantize.find(:all, :order => 'price ASC', 
        :conditions => "(#{clustersquery}) #{(session.filter || filters) && !Cluster.filterquery(session,filters).blank? ? ' and '+Cluster.filterquery(session,filters) : ''}#{
          session.searchpids.blank? ? '' : ' and ('+session.searchpids+')'}")
    end
    @nodes
  end
  
  #The represetative product for this cluster
  def representative(session)
    node = nodes(session).first
    session.product_type.constantize.find(node.product_id) if node
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
          des <<  session.product_type.constantize::ContinuousFeaturesDescLow[f.name]
        elsif (clusterR[0]>=high)
          des <<  session.product_type.constantize::ContinuousFeaturesDescHigh[f.name]
        end
      end 
      res = des.join(', ')
      res.blank? ? 'All Purpose' : res
  end
  
  def isEmpty(session, filters=nil)
    nodes(session, filters).empty?
  end
end