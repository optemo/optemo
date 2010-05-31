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
  
  def cont_specs
    @clusters.map(&:cont_specs).flatten
  end
  
  def ranges(featureName)
    @range ||= {}
    if @range[featureName].nil?
      nodes_min = cont_specs.select{|s|s.name == featurename}.map(&:min).sort[0]
      nodes_max = cont_specs.select{|s|s.name == featurename}.map(&:max).sort[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end
  
  def bin_specs
    @clusters.map(&:bin_specs).flatten
  end
  
  def indicator(featureName)
    indic = false
      values = bin_specs.select{|s|s.name == featurename}
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
        @nodes = Node.find(:all, :conditions => "(#{clustersquery}) #{!Cluster.filterquery.blank? ? ' and '+Cluster.filterquery : ''}")
      end
    end
    @nodes
  end
  
  #The representative product for this cluster
  def representative
    Product.cached(nodes.first.product_id)
  end
  
  def size
    nodes.length
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