class MergedCluster
  include CachingMemcached
  attr_reader :clusters
  
  def initialize(clusters)
    @clusters = clusters
  end
  
  
  def self.fromIDs(clusters,session,searchpids)
    clusterobj = []
    clusters.compact.each do |c|
      newcluster = $clustermodel.find(c.to_i)
      clusterobj << newcluster unless newcluster.nil? || newcluster.isEmpty(session,searchpids)
    end
    new(clusterobj)
  end
  
  def id
    @clusters.map{|c|c.id}.join('+')
  end
  
  def waterproof
    @clusters.map{|c|c.waterproof}.inject(true){|a,b| a && b}
  end
  
  def slr
    @clusters.map{|c|c.slr}.inject(true){|a,b| a && b}
  end
  
  def parent_id
    @clusters.map{|c| c.parent_id}.sort[0]
  end
  
  def layer
    @clusters.map{|c| c.layer}.sort[0]
  end    
  #The subclusters
  def children(session, searchpids)
    @clusters
  end
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(session, searchpids, dC = [])
    clusters.map{|c| c.deepChildren(session, searchpids)}.flatten
  end
  
  def ranges(featureName, session, searchpids)
    @range ||= {}
    if @range[featureName].nil?
      values = nodes(session, searchpids).map{|n| n.send(featureName)}.sort
      nodes_min = values[0]
      nodes_max = values[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end
  
  def indicator(featureName, session, searchpids)
    indic = false
    values = nodes(session, searchpids).map{|n| n.send(featureName)}
    if values.index(false).nil? # they are all the same
        indic = true
    end
    indic
  end
  
  def nodes(session, searchpids)
    unless @nodes
      clustersquery = @clusters.map{|c| "cluster_id = #{c.id}"}.join(' or ')
      if clustersquery.blank?
        @nodes = []
      else
        @nodes = $nodemodel.find(:all, :conditions => "(#{clustersquery}) #{session.filter && !Cluster.filterquery(session).blank? ?
        ' and '+Cluster.filterquery(session) : ''}#{!session.filter || searchpids.blank? ? '' : ' and ('+searchpids+')'}")
      end
    end
    @nodes
  end
  
  #The representative product for this cluster
  def representative(session, searchpids)
    unless @rep
      node = nodes(session, searchpids).first
      @rep = $model.find(node.product_id) if node
    end
    @rep
  end 
  
  def size(session, searchpids)
    unless @size
      if session.filter
        @size = nodes(session, searchpids).length
      else
        @size = @clusters.map{|c|c.cluster_size}.sum
      end
    end
    @size
  end

  def isEmpty(session, searchpids)
    nodes(session, searchpids).empty?
  end
  
  def clearCache
    @clusters.each{|c|c.clearCache}
    @nodes = nil
    @size = nil
    @rep = nil
    @range = nil
    @utility = nil
  end
  
  def utility(session, searchpids)
    if size(session, searchpids) == 0
      @utility ||= 0
    else
      @utility ||= @clusters.map{|c|c.utility(session)}.sum/size(session, searchpids)
    end
  end
end