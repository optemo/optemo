class MergedCluster
  include CachingMemcached
  attr_reader :clusters
  
  def initialize(clusters)
    @clusters = clusters
  end
  
  
  def self.fromIDs(clusters)
    clusterobj = []
    clusters.compact.each do |c|
      newcluster = Cluster.cached(c.to_i)
      clusterobj << newcluster unless newcluster.nil? || newcluster.isEmpty
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
  def children
    @clusters
  end
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(dC = [])
    clusters.map{|c| c.deepChildren}.flatten
  end
  
  def ranges(featureName)
    @range ||= {}
    if @range[featureName].nil?
      values = nodes.map{|n| n.send(featureName)}.sort
      nodes_min = values[0]
      nodes_max = values[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end
  
  def indicator(featureName)
    indic = false
    values = nodes.map{|n| n.send(featureName)}
    if values.index(false).nil? # they are all the same
        indic = true
    end
    indic
  end
  
  def nodes
    unless @nodes
      clustersquery = @clusters.map{|c| "cluster_id = #{c.id}"}.join(' or ')
      if clustersquery.blank?
        @nodes = []
      else
        @nodes = $nodemodel.find(:all, :conditions => "(#{clustersquery}) #{Session.current.filter && !Cluster.filterquery(Session.current).blank? ? ' and '+Cluster.filterquery(Session.current) : ''}#{!Session.current.filter || Session.current.keywordpids.blank? ? '' : ' and ('+Session.current.keywordpids+')'}")
      end
    end
    @nodes
  end
  
  #The representative product for this cluster
  def representative
    unless @rep
      node = nodes.first
      @rep = Cluster.cached(node.product_id) if node
    end
    @rep
  end 
  
  def size
    unless @size
      if Session.current.filter
        @size = nodes.length
      else
        @size = @clusters.map{|c|c.cluster_size}.sum
      end
    end
    @size
  end

  def isEmpty
    nodes.empty?
  end
  
  def clearCache
    @clusters.each{|c|c.clearCache}
    @nodes = nil
    @size = nil
    @rep = nil
    @range = nil
    @utility = nil
  end
  
  def utility
    if size == 0
      @utility ||= 0
    else
      @utility ||= @clusters.map{|c|c.utility}.sum/@clusters.length
    end
  end
end