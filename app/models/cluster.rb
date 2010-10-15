class Cluster < ActiveRecord::Base
  has_many :nodes
  has_many :products, :through => :nodes
  has_many :cont_specs, :through => :products
  has_many :bin_specs, :through => :products
  
  def self.byparent(id)
    return nil if Session.current.directLayout
    current_version = Session.current.version
    #Need to check by version and type because of the root clusters with parent id 0
    CachingMemcached.cache_lookup("Clusters#{current_version}#{id}#{Session.current.product_type}"){find_all_by_parent_id_and_version_and_product_type(id, current_version, Session.current.product_type)}
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Cluster#{id}"){find(id)}
  end
  
  #The subclusters
  def children
    unless @children
      @children = Cluster.byparent(id)
      #Check that children are not empty
      if !Cluster.filterquery.blank?
        @children = @children.reject{|c| c.isEmpty}
      end
    end
    @children
  end
  
  # finding the deepChildren(clusters with size 1) in clusters
  def deepChildren(dC = [])
    #store the cluster id if the cluster_size is 1 and the cluster accepts the filtering conditions 
    if (self.cluster_size == 1) && (self.size>0)
      dC << self
    else
      mychildren = Cluster.byparent(id)
      mychildren.each do |mc|
          dC = mc.deepChildren(dC)
      end  
    end 
    dC
  end
  
  #Maybe we can cache this ***We need a join here
  def ranges(featureName)
    @range ||= {}
    if @range[featureName].nil?
      nodes_min = cont_specs.select{|s|s.name == featurename}.map(&:min).sort[0]
      nodes_max = cont_specs.select{|s|s.name == featurename}.map(&:max).sort[-1]
      @range[featureName] = [nodes_min, nodes_max]    
    end
    @range[featureName]
  end

# this could be integrated with ranges later
  def indicator(featureName)
    indic = false
      values = bin_specs.select{|s|s.name == featurename}
      if values.index(false).nil? # they are all the same
          indic = true
      end 
    indic
  end
  
  def nodes(search = nil)
    unless @nodes
      fq = Cluster.filterquery(search)
      unless (fq.blank?)
        @nodes = Node.where(["cluster_id = ?#{' and '+fq unless fq.blank?}", id]).all
      else 
        @nodes = Node.bycluster(id)
      end
    end
    @nodes
  end
  
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    Product.cached(nodes.first.product_id) if nodes.first
  end
  
  def self.filterquery(search=nil, tablename="")
    fqarray = []
    current_search = search.nil? ? Session.current.search : search
    return nil if current_search.nil?
    current_search.userdataconts.each do |d|
      fqarray << "#{tablename}product_id in (select product_id from cont_specs where value <= #{d.max+0.00001} and name = '#{d.name}')"
      fqarray << "#{tablename}product_id in (select product_id from cont_specs where value >= #{d.min-0.00001} and name = '#{d.name}')"
    end
    current_search.userdatacats.group_by(&:name).each do |name, ds|
      cats = ds.map{|d| "#{tablename}product_id in (select product_id from cat_specs where value = '#{d.value}' and name = '#{name}')"}
      fqarray << "(#{cats.join(' OR ')})"
    end
    current_search.userdatabins.each do |d|
      fqarray << "#{tablename}product_id in (select product_id from bin_specs where value = #{d.value} and name = '#{d.name}')"
    end
    current_search.userdatasearches.each do |d|
      fqarray << d.keywordpids
    end
    fqarray.join(" AND ")
  end
  
  def size
    nodes.length
  end
  
  def self.findFilteringConditions(session)
    session.features.attributes.reject {|key, val| key=='id' || key=='session_id' || key.index('_pref') || key=='created_at' || key=='updated_at' || key=='search_id'}
  end
  
  
  
  
  def self.standarize_data(specs)
    dim = specs[0].length
    
  
  end
  
  def self.get_mean_var()
    
  end
  
    
  def self.kmeans(number_clusters, specs)
  
  
  end
  
  
  
  
  def isEmpty(search = nil)
    nodes(search).empty?
  end
  
  def clearCache
    @nodes = nil
    @range = nil
    @children = nil
  end
  
  def utility
    nodes.map{|n|n.utility}.sum/size
  end
  
end
