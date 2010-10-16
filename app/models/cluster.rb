class Cluster
  attr :products
  
  def initialize(products)
    @products = products
  end
  
  #Unique key for memcache lookup using BER-compressed integer
  def key
    @products.pack("w*")
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Cluster#{id}"){find(id)}
  end
  
  #The subclusters
  def children
    unless @children
      specs = ContSpec.cachemany(@products)
      #need to prepare specs
      cluster_ids = Cluster.kmeans(9,specs)
      @children = Cluster.group_by_clusterids(products,cluster_ids)
      representative #Calculate representative at the same time
    end
    @children
  end
  
  #The represetative product for this cluster, assumes nodes ordered by utility
  def representative
    unless @rep
      utility_list = ContSpec.cachemany_with_ids_hash(@products, "utility")
      @rep = Product.cached(utility_list.max.product_id)
    end
    @rep
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
  
  #Grouping products by cluster_ids
  def self.group_by_clusterids(product_ids, cluster_ids)
    product_ids.group_by{|i|cluster_ids[product_ids.index(i)]}.values.sort{|a,b| b.length <=> a.length}
  end
  
  #Euclidian distance function
  def self.distance(point1, point2)
    dist = 0
    point1.each_index do |i|
      diff = point1[i]-point2[i]
      dist += diff*diff
    end
    dist
  end
end
