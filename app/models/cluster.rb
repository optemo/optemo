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
      @children = Cluster.group_by_clusterids(products,cluster_ids).map{|product_ids|Cluster.new(product_ids)}
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
  
  def size
    @products.size
  end
  
  def numclusters
    children.size
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
